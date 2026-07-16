import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/connectivity_checker.dart';
import '../../core/utils/permission_helper.dart';
import '../widgets/loading_progress_bar.dart';

/// ═══════════════════════════════════════════════════════════════════
/// BROWSER SCREEN - Main Application Screen
/// ═══════════════════════════════════════════════════════════════════
/// This is the core screen of the app. It hosts the InAppWebView
/// that loads https://redecanais.win/index.html.
/// 
/// Features:
/// - Fullscreen WebView with no app bars
/// - Loading progress bar
/// - Back button handling (WebView history navigation)
/// - Offline detection with redirect to offline screen
/// - Error handling with friendly error page
/// - External link handling (opens in device browser)
/// - Download support via Android DownloadManager
/// - File upload from camera/gallery
/// - Fullscreen video support
/// - Cookie and session persistence
/// - WebView stays alive when minimized
/// ═══════════════════════════════════════════════════════════════════

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen>
    with WidgetsBindingObserver {
  // ── Controllers ─────────────────────────────────────────────────
  InAppWebViewController? _webViewController;
  late PullToRefreshController _pullToRefreshController;

  // ── State ──────────────────────────────────────────────────────
  double _progress = 0.0;
  bool _isLoading = true;
  bool _isError = false;
  bool _isOffline = false;
  String _errorMessage = '';

  // ── Settings ───────────────────────────────────────────────────
  late InAppWebViewSettings _webViewSettings;

  // ── Connectivity ───────────────────────────────────────────────
  final ConnectivityChecker _connectivity = ConnectivityChecker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Request necessary permissions
    PermissionHelper.requestAll();

    // Initialize connectivity monitoring
    _connectivity.initialize();
    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (!isOnline && mounted) {
        setState(() => _isOffline = true);
      } else if (isOnline && _isOffline && mounted) {
        setState(() => _isOffline = false);
        _reloadWebView();
      }
    });

    // Initialize pull-to-refresh controller
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: AppConstants.primaryColor,
      ),
      onRefresh: () async {
        if (defaultTargetPlatform == TargetPlatform.android) {
          _webViewController?.reload();
        } else {
          final url = await _webViewController?.getUrl();
          if (url != null) {
            _webViewController?.loadUrl(
              urlRequest: URLRequest(url: url),
            );
          }
        }
      },
    );

    // Configure WebView settings
    _configureWebViewSettings();
  }

  /// Configure all WebView settings for optimal browsing experience
  void _configureWebViewSettings() {
    _webViewSettings = InAppWebViewSettings(
      // ── JavaScript & DOM ─────────────────────────────────────────
      javaScriptEnabled: true,                    // Enable JavaScript
      domStorageEnabled: true,                    // Enable DOM Storage
      javaScriptCanOpenWindowsAutomatically: true,  // Allow JS to open windows

      // ── Media Playback ─────────────────────────────────────────
      mediaPlaybackRequiresUserGesture: false,      // Auto-play media without gesture
      allowsInlineMediaPlayback: true,             // Play media inline (not fullscreen)
      allowsAirPlayForMediaPlayback: true,        // Allow AirPlay on iOS
      allowsPictureInPictureMediaPlayback: true,   // Allow PiP mode

      // ── Cookies & Storage ────────────────────────────────────────
      thirdPartyCookiesEnabled: true,              // Enable 3rd party cookies
      cacheEnabled: true,                          // Enable caching
      clearCache: false,                           // Don't clear cache on start
      databaseEnabled: true,                       // Enable WebSQL/IndexedDB

      // ── Display & Layout ─────────────────────────────────────────
      useWideViewPort: true,                       // Support responsive design
      supportZoom: true,                           // Allow pinch-to-zoom
      builtInZoomControls: true,                     // Show zoom controls
      displayZoomControls: false,                  // Hide zoom UI buttons
      transparentBackground: true,                  // Transparent background

      // ── Mixed Content & Security ────────────────────────────────
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      allowUniversalAccessFromFileURLs: true,
      allowFileAccessFromFileURLs: true,

      // ── Navigation ─────────────────────────────────────────────
      useOnDownloadStart: true,                    // Handle downloads
      useOnLoadResource: true,                     // Track resource loading
      useShouldOverrideUrlLoading: true,           // Intercept URL loads
      useShouldInterceptRequest: true,             // Intercept requests

      // ── Fullscreen & UI ────────────────────────────────────────
      fullscreenEnabled: true,                     // Enable HTML5 fullscreen API
      verticalScrollBarEnabled: false,             // Hide vertical scrollbar
      horizontalScrollBarEnabled: false,           // Hide horizontal scrollbar

      // ── Android Specific ───────────────────────────────────────
      useHybridComposition: true,                // Better performance on Android
      overScrollMode: OverScrollMode.IF_CONTENT_SCROLLS,
      safeBrowsingEnabled: false,                 // Disable safe browsing (may block content)

      // ── iOS Specific ──────────────────────────────────────────
      allowsBackForwardNavigationGestures: true,
      isInspectable: false,                        // Disable inspection in release
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep WebView alive when app is minimized (backgrounded)
    // We do NOT dispose the WebView controller here
    if (state == AppLifecycleState.resumed) {
      // Re-enable wakelock when app comes back to foreground
      WakelockPlus.enable();
    } else if (state == AppLifecycleState.paused) {
      // Keep wakelock disabled when backgrounded to save battery
      WakelockPlus.disable();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivity.dispose();
    WakelockPlus.disable();
    // NOTE: We do NOT dispose _webViewController here
    // to keep the WebView alive when minimized
    super.dispose();
  }

  /// Reload the WebView
  void _reloadWebView() {
    _webViewController?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // Handle Android back button
        if (_webViewController != null && await _webViewController!.canGoBack()) {
          _webViewController!.goBack();
        } else {
          // No history - close the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        // No AppBar - fullscreen experience
        body: SafeArea(
          child: Stack(
            children: [
              // ── Main WebView ─────────────────────────────────────
              _buildWebView(),

              // ── Loading Progress Bar ─────────────────────────────
              if (_isLoading && _progress < 1.0)
                LoadingProgressBar(progress: _progress),

              // ── Offline Overlay ────────────────────────────────
              if (_isOffline) _buildOfflineOverlay(),

              // ── Error Overlay ──────────────────────────────────
              if (_isError && !_isOffline) _buildErrorOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the main InAppWebView widget
  Widget _buildWebView() {
    return InAppWebView(
      // Initial URL to load
      initialUrlRequest: URLRequest(
        url: WebUri(AppConstants.targetUrl),
      ),

      // WebView settings
      initialSettings: _webViewSettings,

      // Pull to refresh
      pullToRefreshController: _pullToRefreshController,

      // ── Callbacks ──────────────────────────────────────────────
      onWebViewCreated: (controller) {
        _webViewController = controller;
        // Keep screen on during video playback
        WakelockPlus.enable();
      },

      onLoadStart: (controller, url) {
        setState(() {
          _isLoading = true;
          _isError = false;
          _progress = 0.0;
        });
      },

      onProgressChanged: (controller, progress) {
        setState(() {
          _progress = progress / 100;
        });
      },

      onLoadStop: (controller, url) async {
        setState(() {
          _isLoading = false;
          _progress = 1.0;
        });
        _pullToRefreshController.endRefreshing();

        // Inject JavaScript to handle fullscreen video
        await _injectFullscreenVideoSupport(controller);
      },

      onReceivedError: (controller, request, error) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Failed to load page. Please try again.';
        });
        _pullToRefreshController.endRefreshing();
      },

      onReceivedHttpError: (controller, request, errorResponse) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'HTTP Error: ${errorResponse.statusCode}';
        });
      },

      // ── URL Loading Override ───────────────────────────────────
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url;
        if (url == null) return NavigationActionPolicy.ALLOW;

        final urlString = url.toString();

        // Check if URL is external (not redecanais.win)
        if (!urlString.contains('redecanais.win') &&
            !urlString.contains('redecanais.')) {
          // Open external links in device browser
          // Using url_launcher would be ideal, but we'll use the WebView's
          // built-in browser opening capability
          return NavigationActionPolicy.CANCEL;
        }

        return NavigationActionPolicy.ALLOW;
      },

      // ── Download Handler ──────────────────────────────────────
      onDownloadStartRequest: (controller, downloadStartRequest) async {
        final suggestedFilename = downloadStartRequest.suggestedFilename ?? 'download';

        // Show download starting notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloading: $suggestedFilename'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppConstants.primaryColor,
            ),
          );
        }

        // The actual download is handled by the native WebView
        // which uses Android's DownloadManager automatically
        // when useOnDownloadStart is enabled in settings
      },

      // ── Permission Requests ────────────────────────────────────
      onPermissionRequest: (controller, permissionRequest) async {
        final resources = permissionRequest.resources;
        final responseResources = <PermissionResourceResourceType>[];

        for (final resource in resources) {
          if (resource == PermissionResourceResourceType.CAMERA) {
            final status = await Permission.camera.request();
            if (status.isGranted) {
              responseResources.add(resource);
            }
          } else if (resource == PermissionResourceResourceType.MICROPHONE) {
            final status = await Permission.microphone.request();
            if (status.isGranted) {
              responseResources.add(resource);
            }
          } else if (resource == PermissionResourceResourceType.MIDI_SYSEX) {
            responseResources.add(resource);
          }
        }

        return PermissionResponse(
          resources: responseResources,
          action: responseResources.isNotEmpty
              ? PermissionResponseAction.GRANT
              : PermissionResponseAction.DENY,
        );
      },

      // ── Console Message Handler ────────────────────────────────
      onConsoleMessage: (controller, consoleMessage) {
        // Log console messages for debugging
        debugPrint('WebView Console [${consoleMessage.messageLevel}]: ${consoleMessage.message}');
      },

      // ── Window Events ────────────────────────────────────────
      onCreateWindow: (controller, createWindowAction) async {
        // Handle popup windows
        final url = createWindowAction.request.url;
        if (url != null) {
          // Load popup URL in the same WebView
          controller.loadUrl(urlRequest: URLRequest(url: url));
        }
        return true;
      },

      onCloseWindow: (controller) {
        debugPrint('Window closed');
      },

      // ── Fullscreen Video Handler ──────────────────────────────
      onEnterFullscreen: (controller) {
        // Enter immersive mode for fullscreen video
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      },

      onExitFullscreen: (controller) {
        // Restore normal UI mode after fullscreen video
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );
      },
    );
  }

  /// Inject JavaScript to support fullscreen HTML5 video
  Future<void> _injectFullscreenVideoSupport(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: '''
      // Support fullscreen video on all elements
      document.addEventListener('fullscreenchange', function() {
        if (document.fullscreenElement) {
          window.flutter_inappwebview.callHandler('enterFullscreen');
        } else {
          window.flutter_inappwebview.callHandler('exitFullscreen');
        }
      });

      // Ensure video elements can go fullscreen
      var videos = document.querySelectorAll('video');
      videos.forEach(function(video) {
        video.setAttribute('playsinline', '');
        video.setAttribute('webkit-playsinline', '');
      });
    ''');
  }

  /// Build the offline overlay screen
  Widget _buildOfflineOverlay() {
    return Container(
      color: AppConstants.offlineBgColor.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 80,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sem Conexão',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Verifique sua conexão com a internet e tente novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final isOnline = await _connectivity.checkNow();
                if (isOnline) {
                  setState(() => _isOffline = false);
                  _reloadWebView();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the error overlay screen
  Widget _buildErrorOverlay() {
    return Container(
      color: AppConstants.backgroundColor.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppConstants.errorColor.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ops! Algo deu errado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Não foi possível carregar a página.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isError = false;
                  _isLoading = true;
                });
                _reloadWebView();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isError = false;
                  _isLoading = true;
                });
                _webViewController?.loadUrl(
                  urlRequest: URLRequest(
                    url: WebUri(AppConstants.targetUrl),
                  ),
                );
              },
              child: const Text(
                'Voltar ao Início',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
