import { createHmac, randomBytes, timingSafeEqual } from "node:crypto";

/**
 * Kod QR na pieczątki. Ten sam format co lib/loyalty/stamp_code.dart:
 * `IR1.<nonce>.<pieczątki>.<ważny do, sekundy unix>.<podpis>`,
 * a naklejka przy ladzie ma prefiks `IR1S` i jako nonce stały id naklejki.
 * Podpis to pierwsze 16 bajtów HMAC-SHA256 w base64url bez `=`.
 */
export const PREFIX = "IR1";
export const STICKER_PREFIX = "IR1S";
export const MAX_STAMPS = 5;
export const DAILY_SCAN_LIMIT = 2;
export const CARD_GOAL = 10;

export interface StampCode {
  nonce: string;
  stamps: number;
  expiresAt: Date;
  sticker: boolean;
}

function b64url(buf: Buffer): string {
  return buf.toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function signature(key: Buffer, payload: string): string {
  return b64url(createHmac("sha256", key).update(payload, "utf8").digest().subarray(0, 16));
}

function payloadOf(code: StampCode): string {
  return `${code.sticker ? STICKER_PREFIX : PREFIX}.${code.nonce}.${code.stamps}.${Math.floor(code.expiresAt.getTime() / 1000)}`;
}

export function sign(code: StampCode, key: Buffer): string {
  const payload = payloadOf(code);
  return `${payload}.${signature(key, payload)}`;
}

export function newNonce(): string {
  // 9 bajtów jak w aplikacji: 12 znaków bez dopełnienia.
  return b64url(randomBytes(9));
}

/** Sprawdza format i podpis. Zwraca null dla obcego albo podrobionego kodu. */
export function verify(raw: string, key: Buffer): StampCode | null {
  const parts = raw.trim().split(".");
  if (parts.length !== 5 || (parts[0] !== PREFIX && parts[0] !== STICKER_PREFIX)) return null;
  if (!/^[A-Za-z0-9_-]{1,64}$/.test(parts[1])) return null;
  if (!/^\d+$/.test(parts[2]) || !/^\d+$/.test(parts[3])) return null;
  const stamps = Number(parts[2]);
  const exp = Number(parts[3]);
  if (stamps < 1 || stamps > MAX_STAMPS) return null;
  const expected = Buffer.from(signature(key, parts.slice(0, 4).join(".")));
  const given = Buffer.from(parts[4]);
  if (expected.length !== given.length || !timingSafeEqual(expected, given)) return null;
  return { nonce: parts[1], stamps, expiresAt: new Date(exp * 1000), sticker: parts[0] === STICKER_PREFIX };
}

/** Dzień w Warszawie, `RRRR-MM-DD`. Dzienny limit skanów odnawia się o północy czasu polskiego. */
export function warsawDay(date: Date): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Warsaw",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

export type ClaimStatus = "added" | "invalid" | "expired" | "alreadyUsed" | "dailyLimit" | "cardFull";

export interface ClaimInput {
  code: StampCode | null;
  now: Date;
  /** Kod jednorazowy już zużyty. */
  nonceUsed: boolean;
  /** Naklejka unieważniona albo nieznana. */
  stickerRevoked: boolean;
  scansToday: number;
  stamps: number;
}

export interface ClaimDecision {
  status: ClaimStatus;
  stamps: number;
}

/** Ta sama kolejność sprawdzeń co LocalStampCodeService.claim w aplikacji. */
export function decideClaim(i: ClaimInput): ClaimDecision {
  const no = (status: ClaimStatus): ClaimDecision => ({ status, stamps: 0 });
  if (i.code === null) return no("invalid");
  if (i.code.sticker && i.stickerRevoked) return no("invalid");
  if (i.now.getTime() >= i.code.expiresAt.getTime()) return no("expired");
  if (!i.code.sticker && i.nonceUsed) return no("alreadyUsed");
  if (i.scansToday >= DAILY_SCAN_LIMIT) return no("dailyLimit");
  const missing = CARD_GOAL - i.stamps;
  // Pełna karta: kod zostaje ważny, żeby klient mógł go użyć po odebraniu nagrody.
  if (missing <= 0) return no("cardFull");
  return { status: "added", stamps: Math.max(1, Math.min(i.code.stamps, missing)) };
}
