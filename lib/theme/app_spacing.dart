import 'package:flutter/material.dart';

// ── 8px spacing grid ─────────────────────────────────────────────────────────
const kS4 = 4.0;
const kS6 = 6.0;
const kS8 = 8.0;
const kS12 = 12.0;
const kS16 = 16.0;
const kS20 = 20.0;
const kS24 = 24.0;
const kS32 = 32.0;
const kS48 = 48.0;

// ── Border radius tokens ─────────────────────────────────────────────────────
const kRadiusSm = 8.0;
const kRadiusMd = 12.0; // cards, inputs, buttons — default
const kRadiusLg = 16.0; // modals, large containers
const kRadiusXl = 20.0; // hero cards, showcase areas
const kRadiusPill = 100.0; // pills / chips

// ── Common page horizontal padding ───────────────────────────────────────────
const kPagePadding = 20.0;

// ── Shadow presets ───────────────────────────────────────────────────────────
const kShadowSm = [
  BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
];

const kShadowMd = [
  BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
];

const kShadowLg = [
  BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
];

const kShadowGlow = [
  BoxShadow(color: Color(0x306366F1), blurRadius: 20, spreadRadius: 2),
];

// ── Duration presets ─────────────────────────────────────────────────────────
const kDurationFast = Duration(milliseconds: 150);
const kDurationNormal = Duration(milliseconds: 300);
const kDurationSlow = Duration(milliseconds: 500);
const kDurationEntrance = Duration(milliseconds: 600);

// ── Curve presets ────────────────────────────────────────────────────────────
const kCurveEntrance = Curves.easeOutCubic;
const kCurveHover = Curves.easeOut;
