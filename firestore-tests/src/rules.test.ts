// Testy reguł Firestore na emulatorze: `npm test` w firestore-tests (wymaga Javy).
import { readFileSync } from "node:fs";
import { after, before, beforeEach, test } from "node:test";

import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { addDoc, collection, deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from "firebase/firestore";

let env: RulesTestEnvironment;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-icerolls",
    firestore: { rules: readFileSync(`${__dirname}/../../firestore.rules`, "utf8"), host: "127.0.0.1", port: 8080 },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "admins/szefowa@gmail.com"), { role: "owner" });
    await setDoc(doc(db, "admins/obsluga@gmail.com"), { role: "staff" });
    await setDoc(doc(db, "menuItems/gofr"), { categoryId: "waffles", name: { pl: "Gofr", en: "Waffle" }, prices: [], active: true });
    await setDoc(doc(db, "users/ala"), { displayName: "Ala", marketingConsent: false, stamps: 3, rewardsRedeemed: 0 });
    await setDoc(doc(db, "users/pelna"), { displayName: "Ewa", marketingConsent: false, stamps: 10, rewardsRedeemed: 1 });
  });
});

after(async () => {
  await env?.cleanup();
});

const guest = () => env.unauthenticatedContext().firestore();
const customer = (uid = "ala") => env.authenticatedContext(uid, { email: `${uid}@example.com`, email_verified: true }).firestore();
// E-mail w tokenie wielkimi literami: reguły porównują małymi.
const owner = () => env.authenticatedContext("szefowa", { email: "Szefowa@gmail.com", email_verified: true }).firestore();
const staff = () => env.authenticatedContext("obsluga", { email: "obsluga@gmail.com", email_verified: true }).firestore();
const unverifiedOwner = () => env.authenticatedContext("podszywka", { email: "szefowa@gmail.com", email_verified: false }).firestore();
const fakeClaim = () => env.authenticatedContext("ktos", { email: "ktos@x.pl", email_verified: true, role: "owner" }).firestore();

const stampUpdate = (stamps: number, rewardsRedeemed: number) => ({ stamps, rewardsRedeemed, lastStampAt: serverTimestamp() });

test("menu czyta każdy, zmienia tylko właściciel", async () => {
  await assertSucceeds(getDoc(doc(guest(), "menuItems/gofr")));
  await assertFails(setDoc(doc(guest(), "menuItems/gofr"), { active: false }));
  await assertFails(updateDoc(doc(customer(), "menuItems/gofr"), { active: false }));
  await assertFails(setDoc(doc(customer(), "promotions/p"), { active: true }));
  await assertFails(setDoc(doc(fakeClaim(), "shop/settings"), { name: "x" }));
  await assertFails(setDoc(doc(unverifiedOwner(), "shop/settings"), { name: "x" }));
  await assertSucceeds(setDoc(doc(owner(), "menuItems/lody"), { categoryId: "rolls", name: { pl: "Lody", en: "Rolls" }, prices: [] }));
  await assertSucceeds(setDoc(doc(owner(), "shop/settings"), { name: "Ice Rolls" }));
  await assertSucceeds(deleteDoc(doc(owner(), "menuItems/lody")));
});

test("obsługa może tylko wyłączyć pozycję", async () => {
  await assertSucceeds(updateDoc(doc(staff(), "menuItems/gofr"), { active: false }));
  await assertFails(updateDoc(doc(staff(), "menuItems/gofr"), { prices: [{ grosze: 1 }] }));
  await assertFails(setDoc(doc(staff(), "categories/x"), { name: { pl: "x" } }));
});

test("rola: każdy widzi tylko swój dokument admins", async () => {
  await assertSucceeds(getDoc(doc(owner(), "admins/szefowa@gmail.com")));
  await assertSucceeds(getDoc(doc(customer(), "admins/ala@example.com")));
  await assertFails(getDoc(doc(customer(), "admins/szefowa@gmail.com")));
  await assertFails(setDoc(doc(customer(), "admins/ala@example.com"), { role: "owner" }));
  await assertFails(setDoc(doc(owner(), "admins/ala@example.com"), { role: "owner" }));
});

test("klient nie dopisze sobie pieczątek", async () => {
  await assertSucceeds(getDoc(doc(customer(), "users/ala")));
  await assertFails(getDoc(doc(customer("ola"), "users/ala")));
  await assertSucceeds(updateDoc(doc(customer(), "users/ala"), { marketingConsent: true }));
  await assertFails(updateDoc(doc(customer(), "users/ala"), stampUpdate(4, 0)));
  await assertFails(updateDoc(doc(customer(), "users/ala"), { role: "owner" }));
  const profile = { displayName: "Ola", email: "ola@example.com", marketingConsent: false, createdAt: serverTimestamp() };
  await assertFails(setDoc(doc(customer("ola"), "users/ola"), { ...profile, stamps: 10 }));
  await assertSucceeds(setDoc(doc(customer("ola"), "users/ola"), profile));
});

test("obsługa dopisuje pieczątki w granicach karty", async () => {
  await assertSucceeds(getDoc(doc(staff(), "users/ala")));
  await assertSucceeds(updateDoc(doc(staff(), "users/ala"), stampUpdate(5, 0)));
  await assertFails(updateDoc(doc(staff(), "users/ala"), stampUpdate(11, 0)));
  await assertFails(updateDoc(doc(owner(), "users/ala"), stampUpdate(4, 1)));
  await assertFails(updateDoc(doc(owner(), "users/ala"), stampUpdate(2, 0)));
  await assertFails(updateDoc(doc(owner(), "users/ala"), { ...stampUpdate(5, 0), displayName: "Hack" }));
  await assertSucceeds(updateDoc(doc(owner(), "users/ala"), stampUpdate(10, 0)));
});

test("nagroda tylko z pełnej karty", async () => {
  await assertFails(updateDoc(doc(owner(), "users/ala"), stampUpdate(0, 1)));
  await assertFails(updateDoc(doc(owner(), "users/pelna"), stampUpdate(0, 3)));
  await assertSucceeds(updateDoc(doc(owner(), "users/pelna"), stampUpdate(0, 2)));
});

test("dziennik zmian", async () => {
  const entry = (uid: string) => ({ uid, action: "x", path: "/", at: serverTimestamp() });
  await assertSucceeds(addDoc(collection(owner(), "auditLog"), entry("szefowa")));
  await assertFails(addDoc(collection(owner(), "auditLog"), entry("ktos")));
  await assertFails(addDoc(collection(customer(), "auditLog"), entry("ala")));
  await assertFails(getDoc(doc(staff(), "auditLog/a")));
});

test("wszystko inne zamknięte", async () => {
  await assertFails(getDoc(doc(owner(), "private/x")));
  await assertFails(setDoc(doc(customer(), "stickers/lada-1"), { revoked: false }));
});
