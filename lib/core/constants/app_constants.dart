/// ═══════════════════════════════════════════════════════════════════
/// APP CONSTANTS
/// ═══════════════════════════════════════════════════════════════════
/// Centralized configuration values for the Rede Canais Browser app.
/// All magic strings, URLs, and UI values live here for easy maintenance.
/// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ── App Identity ────────────────────────────────────────────────
  static const String appName = 'Rede Canais Browser';
  static const String appVersion = '1.0.0';

  // ── Target Website ──────────────────────────────────────────────
  /// The website this browser is designed to load.
  /// This app acts only as a browser wrapper and does not modify
  /// or copy the website's content in any way.
  static const String targetUrl = 'https://redecanais.win/index.html';

  // ── Routes ──────────────────────────────────────────────────────
  static const String routeSplash = '/';
  static const String routeBrowser = '/browser';
  static const String routeOffline = '/offline';
  static const String routeError = '/error';

  // ── Colors ──────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFFE50914);   // Netflix-style red
  static const Color accentColor = Color(0xFFFFFFFF);      // White
  static const Color backgroundColor = Color(0xFF141414);  // Dark background
  static const Color errorColor = Color(0xFFE50914);
  static const Color offlineBgColor = Color(0xFF1A1A1A);

  // ── Timing ──────────────────────────────────────────────────────
  static const int splashDurationMs = 2000;  // 2 seconds splash screen
  static const int connectionTimeoutSec = 10;

  // ── Asset Paths ─────────────────────────────────────────────────
  static const String splashLogo = 'assets/images/splash_logo.png';
  static const String offlineIcon = 'assets/icons/offline.png';
  static const String errorIcon = 'assets/icons/error.png';
}
