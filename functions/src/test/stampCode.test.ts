import assert from "node:assert/strict";
import { test } from "node:test";

import { DAILY_SCAN_LIMIT, decideClaim, newNonce, sign, verify, warsawDay } from "../stampCode";

const key = Buffer.from("klucz-testowy", "utf8");

test("podpis zgodny z aplikacją (lib/loyalty/stamp_code.dart)", () => {
  // Kody wygenerowane przez StampCode.sign w Dart tym samym kluczem.
  const code = verify("IR1.abcDEF123_-x.3.1798859045.qHLbgtdb661NtKTgNPSxMQ", key);
  assert.deepEqual(code, { nonce: "abcDEF123_-x", stamps: 3, expiresAt: new Date("2027-01-02T03:04:05Z"), sticker: false });
  const sticker = verify("IR1S.lada-1.1.1830297600.i5DCntGCD6xfvV5W1CAoWA", key);
  assert.equal(sticker?.sticker, true);
  assert.equal(sign(code!, key), "IR1.abcDEF123_-x.3.1798859045.qHLbgtdb661NtKTgNPSxMQ");
});

test("podrobiony albo obcy kod nie przechodzi", () => {
  assert.equal(verify("IR1.abcDEF123_-x.5.1798859045.qHLbgtdb661NtKTgNPSxMQ", key), null);
  assert.equal(verify("IR1.abcDEF123_-x.3.1798859045.qHLbgtdb661NtKTgNPSxMQ", Buffer.from("inny")), null);
  assert.equal(verify("https://example.com", key), null);
  const tooMany = sign({ nonce: "x", stamps: 9, expiresAt: new Date(), sticker: false }, key);
  assert.equal(verify(tooMany, key), null);
});

test("nonce ma 12 znaków base64url", () => {
  assert.match(newNonce(), /^[A-Za-z0-9_-]{12}$/);
});

test("dzień liczony w czasie polskim", () => {
  assert.equal(warsawDay(new Date("2026-11-10T22:59:00Z")), "2026-11-10");
  assert.equal(warsawDay(new Date("2026-11-10T23:01:00Z")), "2026-11-11");
  assert.equal(warsawDay(new Date("2026-07-10T22:01:00Z")), "2026-07-11");
});

test("zasady realizacji kodu", () => {
  const now = new Date("2026-11-10T12:00:00Z");
  const code = { nonce: "n", stamps: 3, expiresAt: new Date("2026-11-10T12:02:00Z"), sticker: false };
  const base = { code, now, nonceUsed: false, stickerRevoked: false, scansToday: 0, stamps: 0 };
  assert.deepEqual(decideClaim(base), { status: "added", stamps: 3 });
  assert.equal(decideClaim({ ...base, code: null }).status, "invalid");
  assert.equal(decideClaim({ ...base, now: code.expiresAt }).status, "expired");
  assert.equal(decideClaim({ ...base, nonceUsed: true }).status, "alreadyUsed");
  assert.equal(decideClaim({ ...base, scansToday: DAILY_SCAN_LIMIT }).status, "dailyLimit");
  assert.equal(decideClaim({ ...base, stamps: 10 }).status, "cardFull");
  assert.deepEqual(decideClaim({ ...base, stamps: 9 }), { status: "added", stamps: 1 });
  const sticker = { ...code, sticker: true };
  assert.equal(decideClaim({ ...base, code: sticker, nonceUsed: true }).status, "added");
  assert.equal(decideClaim({ ...base, code: sticker, stickerRevoked: true }).status, "invalid");
});
