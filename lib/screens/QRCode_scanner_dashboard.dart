import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ── ACLC COLORS ─────────────────────────────────────────────
class ACLCColors {
  static const red  = Color(0xFFFD070C);
  static const navy = Color(0xFF0F136E);
  static const gray = Color(0xFFF5F7FA);
}

// ── MAIN WIDGET ─────────────────────────────────────────────
class QRCodeScannerDashboard extends StatefulWidget {
  const QRCodeScannerDashboard({super.key});

  @override
  State<QRCodeScannerDashboard> createState() =>
      _QRCodeScannerDashboardState();
}

class _QRCodeScannerDashboardState
    extends State<QRCodeScannerDashboard> {
  bool _isScanning = true;
  String? _lastScanned;
  String statusMessage = "Ready to scan";

  // ── REAL STUDENT DATABASE ─────────────────────────────────
  final Map<String, String> studentDB = {
    "ACLC001": "Jeff",
    "ACLC002": "Kath",
    "ACLC003": "Hannah",
    "ACLC004": "Juna",
    "ACLC005": "Jas",
  };

  // ── ON SCAN DETECT ────────────────────────────────────────
  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final barcode = capture.barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null) return;

    setState(() {
      _isScanning = false;
      _lastScanned = code;
    });

    String result;

    // ── VALIDATION ──────────────────────────────────────────
    if (studentDB.containsKey(code)) {
      String studentName = studentDB[code]!;

      // Simulate saving violation
      await Future.delayed(const Duration(milliseconds: 500));

      result = "✅ $studentName recorded";
      statusMessage = "Valid Student";
    } else {
      result = "❌ Unknown QR Code";
      statusMessage = "Invalid student ID";
    }

    if (!mounted) return;

    // ── SHOW RESULT ─────────────────────────────────────────
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result)),
    );

    // Resume scanning
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isScanning = true;
    });
  }

  // ── UI ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Scanner Dashboard"),
        backgroundColor: ACLCColors.navy,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _lastScanned = null;
                statusMessage = "Ready to scan";
                _isScanning = true;
              });
            },
          )
        ],
      ),

      body: Column(
        children: [
          // 📷 SCANNER
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: MobileScannerController(
                detectionSpeed: DetectionSpeed.noDuplicates,
              ),
              onDetect: _onDetect,
            ),
          ),

          // 📊 INFO PANEL
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: ACLCColors.gray,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Status:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    statusMessage,
                    style: const TextStyle(
                        fontSize: 16, color: ACLCColors.navy),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Last Scanned QR:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _lastScanned ?? "No scan yet",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ACLCColors.navy,
                    ),
                  ),

                  const Spacer(),

                  // ▶ BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text("Scan Again"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ACLCColors.navy,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isScanning = true;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}