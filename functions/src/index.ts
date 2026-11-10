import { randomBytes } from "node:crypto";

import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { defineString } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";

import {
  CARD_GOAL,
  DAILY_SCAN_LIMIT,
  MAX_STAMPS,
  STICKER_PREFIX,
  decideClaim,
  newNonce,
  sign,
  verify,
  warsawDay,
} from "./stampCode";

initializeApp();
const db = getFirestore();

// Warszawa, jak baza. maxInstances chroni rachunek przed zalewem zapytań.
setGlobalOptions({ region: "europe-central2", maxInstances: 5 });

/**
 * E-maile właścicieli, oddzielone przecinkami. W GitHub Actions bierze się
 * z sekretu OWNER_EMAILS, żeby adres nie trafił do repozytorium.
 */
const ownerEmails = defineString("OWNER_EMAILS", { default: "" });

type Role = "owner" | "staff";

function roleOf(req: CallableRequest): Role | null {
  const role = req.auth?.token.role;
  return role === "owner" || role === "staff" ? role : null;
}

function requireUser(req: CallableRequest): string {
  if (!req.auth) throw new HttpsError("unauthenticated", "Zaloguj się.");
  return req.auth.uid;
}

function requireStaff(req: CallableRequest): string {
  const uid = requireUser(req);
  if (roleOf(req) === null) throw new HttpsError("permission-denied", "Tylko dla obsługi sklepu.");
  return uid;
}

function requireOwner(req: CallableRequest): string {
  const uid = requireUser(req);
  if (roleOf(req) !== "owner") throw new HttpsError("permission-denied", "Tylko dla właściciela.");
  return uid;
}

function int(value: unknown, min: number, max: number, name: string): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < min || value > max) {
    throw new HttpsError("invalid-argument", `${name}: liczba od ${min} do ${max}.`);
  }
  return value;
}

function uidArg(value: unknown): string {
  if (typeof value !== "string" || !/^[A-Za-z0-9]{1,128}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Zły identyfikator klienta.");
  }
  return value;
}

/** Klucz do podpisu kodów. Tworzony przy pierwszym użyciu, reguły blokują go przed aplikacją. */
let cachedKey: Buffer | null = null;
async function stampKey(): Promise<Buffer> {
  if (cachedKey) return cachedKey;
  const ref = db.doc("private/stampKey");
  const key = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const existing = snap.get("key");
    if (typeof existing === "string") return existing;
    const fresh = randomBytes(32).toString("base64");
    tx.set(ref, { key: fresh, createdAt: FieldValue.serverTimestamp() });
    return fresh;
  });
  cachedKey = Buffer.from(key, "base64");
  return cachedKey;
}

async function audit(uid: string, action: string, path: string, extra: Record<string, unknown> = {}) {
  await db.collection("auditLog").add({ uid, action, path, at: FieldValue.serverTimestamp(), ...extra });
}

// Role

/** Nadaje rolę owner, jeśli zweryfikowany e-mail jest na liście OWNER_EMAILS. */
export const claimOwner = onCall(async (req) => {
  const uid = requireUser(req);
  const email = (req.auth?.token.email ?? "").toLowerCase();
  const verified = req.auth?.token.email_verified === true;
  const owners = ownerEmails
    .value()
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
  if (!verified || !owners.includes(email)) return { role: roleOf(req) };
  if (roleOf(req) === "owner") return { role: "owner" };
  await getAuth().setCustomUserClaims(uid, { role: "owner" });
  await audit(uid, "claimOwner", `users/${uid}`);
  return { role: "owner" };
});

/** Właściciel nadaje albo odbiera rolę innemu kontu (po e-mailu). */
export const setRole = onCall(async (req) => {
  const uid = requireOwner(req);
  const email = req.data?.email;
  const role = req.data?.role;
  if (typeof email !== "string") throw new HttpsError("invalid-argument", "Podaj e-mail.");
  if (role !== "staff" && role !== "owner" && role !== null) throw new HttpsError("invalid-argument", "Zła rola.");
  const user = await getAuth()
    .getUserByEmail(email.trim())
    .catch(() => {
      throw new HttpsError("not-found", "Nie ma konta z tym e-mailem.");
    });
  if (user.uid === uid && role !== "owner") {
    throw new HttpsError("failed-precondition", "Nie możesz odebrać roli sobie.");
  }
  await getAuth().setCustomUserClaims(user.uid, role ? { role } : {});
  await audit(uid, "setRole", `users/${user.uid}`, { role });
  return { uid: user.uid, role };
});

// Kody na pieczątki

/** Obsługa: jednorazowy kod na 1 do 5 pieczątek, ważny najwyżej 10 minut. */
export const issueStampCode = onCall(async (req) => {
  requireStaff(req);
  const stamps = int(req.data?.stamps, 1, MAX_STAMPS, "stamps");
  const validFor = int(req.data?.validForSeconds ?? 120, 30, 600, "validForSeconds");
  const code = sign({ nonce: newNonce(), stamps, expiresAt: new Date(Date.now() + validFor * 1000), sticker: false }, await stampKey());
  return { code };
});

/**
 * Kod naklejki przy ladzie. Nową naklejkę tworzy właściciel, a obsługa
 * może pobrać kod istniejącej (żeby ją wydrukować jeszcze raz).
 */
export const issueSticker = onCall(async (req) => {
  const uid = requireStaff(req);
  const id = req.data?.id;
  if (typeof id !== "string" || !/^[A-Za-z0-9_-]{1,32}$/.test(id)) {
    throw new HttpsError("invalid-argument", "Zły identyfikator naklejki.");
  }
  const ref = db.doc(`stickers/${id}`);
  const snap = await ref.get();
  let validUntil: Date;
  if (snap.exists && snap.get("revoked") !== true) {
    validUntil = (snap.get("validUntil") as Timestamp).toDate();
  } else {
    if (roleOf(req) !== "owner") throw new HttpsError("permission-denied", "Nową naklejkę tworzy właściciel.");
    validUntil = new Date(String(req.data?.validUntil ?? ""));
    const max = Date.now() + 3 * 365 * 24 * 3600 * 1000;
    if (Number.isNaN(validUntil.getTime()) || validUntil.getTime() <= Date.now() || validUntil.getTime() > max) {
      throw new HttpsError("invalid-argument", "Data ważności: w ciągu 3 lat.");
    }
    await ref.set({ validUntil: Timestamp.fromDate(validUntil), revoked: false, createdAt: FieldValue.serverTimestamp() });
    await audit(uid, "issueSticker", `stickers/${id}`);
  }
  return { code: sign({ nonce: id, stamps: 1, expiresAt: validUntil, sticker: true }, await stampKey()), validUntil: validUntil.toISOString() };
});

function scanCounterRef(uid: string, now: Date) {
  return db.doc(`scanCounters/${uid}_${warsawDay(now)}`);
}

/** Klient: ile skanów zostało dziś. */
export const scansLeftToday = onCall(async (req) => {
  const uid = requireUser(req);
  const snap = await scanCounterRef(uid, new Date()).get();
  const used = snap.exists ? Number(snap.get("count") ?? 0) : 0;
  return { scansLeftToday: Math.max(0, DAILY_SCAN_LIMIT - used) };
});

/** Klient: realizuje kod z paragonu albo z naklejki i dopisuje pieczątki na swoje konto. */
export const claimStampCode = onCall(async (req) => {
  const uid = requireUser(req);
  const raw = req.data?.code;
  if (typeof raw !== "string" || raw.length > 200) return { status: "invalid", stamps: 0, scansLeftToday: 0 };
  const code = verify(raw, await stampKey());
  const now = new Date();
  const userRef = db.doc(`users/${uid}`);
  const counterRef = scanCounterRef(uid, now);

  return db.runTransaction(async (tx) => {
    const nonceRef = code && !code.sticker ? db.doc(`stampNonces/${code.nonce}`) : null;
    const stickerRef = code && code.sticker ? db.doc(`stickers/${code.nonce}`) : null;
    const [user, counter, nonce, sticker] = await Promise.all([
      tx.get(userRef),
      tx.get(counterRef),
      nonceRef ? tx.get(nonceRef) : Promise.resolve(null),
      stickerRef ? tx.get(stickerRef) : Promise.resolve(null),
    ]);
    const scansToday = counter.exists ? Number(counter.get("count") ?? 0) : 0;
    const decision = decideClaim({
      code,
      now,
      nonceUsed: nonce?.exists ?? false,
      stickerRevoked: sticker ? !sticker.exists || sticker.get("revoked") === true : false,
      scansToday,
      stamps: Number(user.get("stamps") ?? 0),
    });
    if (decision.status !== "added") {
      return { status: decision.status, stamps: 0, scansLeftToday: Math.max(0, DAILY_SCAN_LIMIT - scansToday) };
    }
    if (nonceRef && code) {
      // Zużyty kod pamiętamy do jego wygaśnięcia; TTL w Firestore może go potem usunąć.
      tx.create(nonceRef, { uid, usedAt: FieldValue.serverTimestamp(), expiresAt: Timestamp.fromDate(code.expiresAt) });
    }
    tx.set(counterRef, { uid, count: scansToday + 1, day: warsawDay(now) }, { merge: true });
    tx.set(
      userRef,
      { stamps: FieldValue.increment(decision.stamps), lastStampAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
    return {
      status: "added",
      stamps: decision.stamps,
      scansLeftToday: DAILY_SCAN_LIMIT - scansToday - 1,
      source: code?.sticker ? `${STICKER_PREFIX}:${code.nonce}` : "code",
    };
  });
});

/** Obsługa: ręczne nabicie pieczątek klientowi (po zeskanowaniu jego kodu `IRU1.<uid>`). */
export const addStamps = onCall(async (req) => {
  const staff = requireStaff(req);
  const uid = uidArg(req.data?.uid);
  const count = int(req.data?.count, 1, MAX_STAMPS, "count");
  const ref = db.doc(`users/${uid}`);
  const added = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Nie ma takiego klienta.");
    const stamps = Number(snap.get("stamps") ?? 0);
    const n = Math.max(0, Math.min(count, CARD_GOAL - stamps));
    if (n > 0) tx.update(ref, { stamps: stamps + n, lastStampAt: FieldValue.serverTimestamp() });
    return n;
  });
  await audit(staff, "addStamps", `users/${uid}`, { count: added });
  return { stamps: added };
});

/** Obsługa: wydanie darmowego loda za pełną kartę. */
export const redeemReward = onCall(async (req) => {
  const staff = requireStaff(req);
  const uid = uidArg(req.data?.uid);
  const ref = db.doc(`users/${uid}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Nie ma takiego klienta.");
    if (Number(snap.get("stamps") ?? 0) < CARD_GOAL) {
      throw new HttpsError("failed-precondition", "Karta nie jest jeszcze pełna.");
    }
    tx.update(ref, {
      stamps: 0,
      rewardsRedeemed: FieldValue.increment(1),
      lastRewardAt: FieldValue.serverTimestamp(),
    });
  });
  await audit(staff, "redeemReward", `users/${uid}`);
  return { ok: true };
});
