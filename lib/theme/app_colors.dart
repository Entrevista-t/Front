import 'package:flutter/material.dart';

// ── Brand ────────────────────────────────────────────────────────────────────
const kAccent = Color(0xFF6366F1); // indigo — enterprise primary

// ── Pastel accents (feature differentiation) ────────────────────────────────
const kAccentTeal = Color(0xFF14B8A6);
const kAccentAmber = Color(0xFFF59E0B);
const kAccentRose = Color(0xFFF43F5E);
const kAccentSky = Color(0xFF38BDF8);

// ── Backgrounds ──────────────────────────────────────────────────────────────
const kBgBase = Color(0xFF0D1117); // page / scaffold background
const kBgSurface = Color(0xFF161B2E); // cards, drawer, appbar
const kBgElevated = Color(0xFF1E2640); // elevated cards, selected states

// ── Text ─────────────────────────────────────────────────────────────────────
const kTextPrimary = Color(0xFFF1F5F9); // headings, strong text
const kTextSecondary = Color(0xFF94A3B8); // body, subtitles, meta
const kTextDisabled = Color(0xFF475569); // disabled, placeholder

// ── Borders ──────────────────────────────────────────────────────────────────
const kBorderSubtle = Color(0x12FFFFFF); // ~7% white — card/input borders

// ── Semantic (scores & status) ────────────────────────────────────────────────
const kScoreGood = Color(0xFF22C55E); // score ≥ 75
const kScoreMid = Color(0xFFF59E0B); // score 50–74
const kScoreLow = Color(0xFFEF4444); // score < 50
const kErrorRed = Color(0xFFEF4444);

// ── Helper ───────────────────────────────────────────────────────────────────

/// Returns the semantic score colour based on a 0–100 value.
Color scoreColor(double score) {
  if (score >= 75) return kScoreGood;
  if (score >= 50) return kScoreMid;
  return kScoreLow;
}
