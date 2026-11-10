// Testy reguł Firestore i Cloud Functions na emulatorach:
//   npm run test:emulator   (wymaga Javy)
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { after, before, test } from "node:test";

import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from "firebase/firestore";

const PROJECT = "demo-icerolls";
let env: RulesTestEnvironment;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: { rules: readFileSync(`${__dirname}/../../../../firestore.rules`, "utf8"), host: "127.0.0.1", port: 8080 },
  });
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "menuItems/gofr"), { categoryId: "waffles", name: { pl: "Gofr", en: "Waffle" }, prices: [], active: true });
    await setDoc(doc(db, "users/ala"), { displayName: "Ala", marketingConsent: false, stamps: 3 });
    await setDoc(doc(db, "private/stampKey"), { key: "tajny" });
  });
});

after(async () => {
  await env?.cleanup();
});

const guest = () => env.unauthenticatedContext().firestore();
const customer = (uid = "ala") => env.authenticatedContext(uid, { email: `${uid}@example.com` }).firestore();
const owner = () => env.authenticatedContext("szefowa", { role: "owner" }).firestore();
const staff = () => env.authenticatedContext("obsluga", { role: "staff" }).firestore();

test("menu czyta każdy, zmienia tylko właściciel", async () => {
  await assertSucceeds(getDoc(doc(guest(), "menuItems/gofr")));
  await assertFails(setDoc(doc(guest(), "menuItems/gofr"), { active: false }));
  await assertFails(updateDoc(doc(customer(), "menuItems/gofr"), { active: false }));
  await assertFails(setDoc(doc(customer(), "promotions/p"), { active: true }));
  await assertSucceeds(
    setDoc(doc(owner(), "menuItems/lody"), { categoryId: "rolls", name: { pl: "Lody", en: "Rolls" }, prices: [] }),
  );
  await assertSucceeds(setDoc(doc(owner(), "shop/settings"), { name: "Ice Rolls" }));
  await assertSucceeds(deleteDoc(doc(owner(), "menuItems/lody")));
});

test("obsługa może tylko wyłączyć pozycję", async () => {
  await assertSucceeds(updateDoc(doc(staff(), "menuItems/gofr"), { active: false }));
  await assertFails(updateDoc(doc(staff(), "menuItems/gofr"), { prices: [{ grosze: 1 }] }));
  await assertFails(setDoc(doc(staff(), "categories/x"), { name: { pl: "x" } }));
});

test("klient nie dopisze sobie pieczątek", async () => {
  await assertSucceeds(getDoc(doc(customer(), "users/ala")));
  await assertFails(getDoc(doc(customer("ola"), "users/ala")));
  await assertSucceeds(updateDoc(doc(customer(), "users/ala"), { marketingConsent: true }));
  await assertFails(updateDoc(doc(customer(), "users/ala"), { stamps: 10 }));
  await assertFails(updateDoc(doc(customer(), "users/ala"), { role: "owner" }));
  await assertFails(
    setDoc(doc(customer("ola"), "users/ola"), {
      displayName: "Ola",
      email: "ola@example.com",
      marketingConsent: false,
      createdAt: serverTimestamp(),
      stamps: 10,
    }),
  );
  await assertSucceeds(
    setDoc(doc(customer("ola"), "users/ola"), {
      displayName: "Ola",
      email: "ola@example.com",
      marketingConsent: false,
      createdAt: serverTimestamp(),
    }),
  );
});

test("klucz i liczniki są tylko dla serwera", async () => {
  await assertFails(getDoc(doc(owner(), "private/stampKey")));
  await assertFails(getDoc(doc(customer(), "scanCounters/ala_2026-11-10")));
  await assertFails(setDoc(doc(customer(), "stampNonces/x"), { uid: "ala" }));
});

test("dziennik zmian", async () => {
  await assertSucceeds(setDoc(doc(owner(), "auditLog/a"), { uid: "szefowa", action: "x", path: "/", at: serverTimestamp() }));
  await assertFails(setDoc(doc(owner(), "auditLog/b"), { uid: "ktos", action: "x", path: "/", at: serverTimestamp() }));
  await assertFails(setDoc(doc(customer(), "auditLog/c"), { uid: "ala", action: "x", path: "/", at: serverTimestamp() }));
  await assertFails(getDoc(doc(staff(), "auditLog/a")));
});

// Cloud Functions przez emulator: logowanie w emulatorze Auth i wywołanie jak z aplikacji.

const AUTH = "http://127.0.0.1:9099";
const FN = `http://127.0.0.1:5001/${PROJECT}/europe-central2`;

async function signUp(email: string): Promise<{ uid: string; token: string }> {
  const res = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email, password: "haslo123", returnSecureToken: true }),
  });
  const body = (await res.json()) as { localId: string; idToken: string };
  return { uid: body.localId, token: body.idToken };
}

async function userDoc(uid: string): Promise<Record<string, unknown> | undefined> {
  let data: Record<string, unknown> | undefined;
  await env.withSecurityRulesDisabled(async (ctx) => {
    data = (await getDoc(doc(ctx.firestore(), `users/${uid}`))).data();
  });
  return data;
}

async function setClaims(uid: string, email: string, claims: object): Promise<string> {
  await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:update`, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: "Bearer owner" },
    body: JSON.stringify({ localId: uid, customAttributes: JSON.stringify(claims) }),
  });
  const res = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email, password: "haslo123", returnSecureToken: true }),
  });
  return ((await res.json()) as { idToken: string }).idToken;
}

async function call<T = Record<string, unknown>>(name: string, token: string, data: object = {}): Promise<{ ok: boolean; result: T; error?: { status: string } }> {
  const res = await fetch(`${FN}/${name}`, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${token}` },
    body: JSON.stringify({ data }),
  });
  const body = (await res.json()) as { result: T; error?: { status: string } };
  return { ok: res.ok, result: body.result, error: body.error };
}

test("pieczątki przez Cloud Functions", async () => {
  await env.clearFirestore();
  const boss = await signUp("szefowa@x.pl");
  const bossToken = await setClaims(boss.uid, "szefowa@x.pl", { role: "owner" });
  const client = await signUp("klient@x.pl");
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), `users/${client.uid}`), { displayName: "K", stamps: 0 }));

  // Klient nie wyda sobie kodu.
  assert.equal((await call("issueStampCode", client.token, { stamps: 5 })).error?.status, "PERMISSION_DENIED");

  const { result: issued } = await call<{ code: string }>("issueStampCode", bossToken, { stamps: 2, validForSeconds: 120 });
  assert.match(issued.code, /^IR1\./);

  const first = await call("claimStampCode", client.token, { code: issued.code });
  assert.deepEqual(first.result, { status: "added", stamps: 2, scansLeftToday: 1, source: "code" });
  const again = await call("claimStampCode", client.token, { code: issued.code });
  assert.equal(again.result.status, "alreadyUsed");

  const forged = issued.code.replace(".2.", ".5.");
  assert.equal((await call("claimStampCode", client.token, { code: forged })).result.status, "invalid");

  const { result: sticker } = await call<{ code: string }>("issueSticker", bossToken, {
    id: "lada-1",
    validUntil: new Date(Date.now() + 86400e3).toISOString(),
  });
  assert.equal((await call("claimStampCode", client.token, { code: sticker.code })).result.status, "added");
  assert.equal((await call("claimStampCode", client.token, { code: sticker.code })).result.status, "dailyLimit");
  assert.deepEqual((await call("scansLeftToday", client.token)).result, { scansLeftToday: 0 });

  const card = await userDoc(client.uid);
  assert.equal(card?.stamps, 3);

  assert.equal((await call("redeemReward", bossToken, { uid: client.uid })).error?.status, "FAILED_PRECONDITION");
  await call("addStamps", bossToken, { uid: client.uid, count: 5 });
  await call("addStamps", bossToken, { uid: client.uid, count: 5 });
  assert.equal((await call("redeemReward", bossToken, { uid: client.uid })).ok, true);
  const after = await userDoc(client.uid);
  assert.equal(after?.stamps, 0);
  assert.equal(after?.rewardsRedeemed, 1);
});

test("rola właściciela z listy OWNER_EMAILS", async () => {
  const other = await signUp("ktos@x.pl");
  assert.deepEqual((await call("claimOwner", other.token)).result, { role: null });
});
