import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/connectivity_checker.dart';

/// ═══════════════════════════════════════════════════════════════════
/// OFFLINE SCREEN
/// ═══════════════════════════════════════════════════════════════════
/// Standalone offline screen shown when there's no internet connection.
/// Includes a Retry button to check connectivity and reload.
/// This screen can be navigated to independently from the browser.
/// ═══════════════════════════════════════════════════════════════════

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Ensure normal UI mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  Future<void> _retryConnection() async {
    setState(() => _isChecking = true);

    final connectivity = ConnectivityChecker();
    final isOnline = await connectivity.checkNow();

    setState(() => _isChecking = false);

    if (isOnline && mounted) {
      // Connection restored - go to browser
      Navigator.of(context).pushReplacementNamed(AppConstants.routeBrowser);
    } else if (mounted) {
      // Still offline - show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ainda sem conexão. Verifique sua internet.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.offlineBgColor,
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          // Close app when back is pressed on offline screen
          SystemNavigator.pop();
        },
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Offline Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 50,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Sem Conexão com a Internet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Parece que você está offline. Verifique sua conexão Wi-Fi ou dados móveis e tente novamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Retry Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : _retryConnection,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _isChecking ? 'Verificando...' : 'Tentar Novamente',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Close App Button
                  TextButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: Text(
                      'Fechar Aplicativo',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
