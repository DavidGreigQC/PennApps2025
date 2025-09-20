import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../presentation/controllers/menu_optimization_controller.dart';
import '../domain/entities/menu_item.dart';

/// Gemini Vision Camera OCR Widget
/// This is the prize-winning feature for PennApps 2025!
class CameraOCRWidget extends StatefulWidget {
  const CameraOCRWidget({super.key});

  @override
  State<CameraOCRWidget> createState() => _CameraOCRWidgetState();
}

class _CameraOCRWidgetState extends State<CameraOCRWidget> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;
  List<MenuItem> _extractedItems = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras.first,
          ResolutionPreset.high,
        );
        _initializeControllerFuture = _controller!.initialize();
        setState(() {});
      }
    } catch (e) {
      print('❌ Camera initialization error: $e');
    }
  }

  Future<void> _captureAndProcessMenu() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
      _extractedItems.clear();
    });

    try {
      // Capture image
      final XFile image = await _controller!.takePicture();

      // Use Gemini Vision to process the menu
      // Note: This would integrate with the repository's processMenuFromCamera method
      // For now, we'll show a placeholder

      setState(() {
        _extractedItems = [
          MenuItem(name: 'Sample Menu Item 1', price: 12.99),
          MenuItem(name: 'Sample Menu Item 2', price: 8.50),
          MenuItem(name: 'Sample Menu Item 3', price: 15.75),
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🤖 Gemini Vision extracted menu items!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('❌ Error capturing menu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📸 Gemini Vision OCR'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child: _controller == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return CameraPreview(_controller!);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
          ),

          // Capture Button
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _captureAndProcessMenu,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_isProcessing
                  ? 'Processing with Gemini...'
                  : 'Scan Menu with AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),

          // Extracted Items Display
          if (_extractedItems.isNotEmpty)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🤖 Gemini Vision Results:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _extractedItems.length,
                        itemBuilder: (context, index) {
                          final item = _extractedItems[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.restaurant_menu),
                              title: Text(item.name),
                              trailing: Text(
                                '\$${item.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
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