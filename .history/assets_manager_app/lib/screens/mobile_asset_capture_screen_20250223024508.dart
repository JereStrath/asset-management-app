import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/mobile_asset_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:your_package_name/screens/asset_details_screen.dart';

class MobileAssetCaptureScreen extends StatefulWidget {
  final String assetId;
  final String assetName;

  MobileAssetCaptureScreen({
    required this.assetId,
    required this.assetName,
  });

  @override
  _MobileAssetCaptureScreenState createState() => _MobileAssetCaptureScreenState();
}

class _MobileAssetCaptureScreenState extends State<MobileAssetCaptureScreen> {
  final _mobileAssetService = MobileAssetService();
  late CameraController _cameraController;
  bool _isRecording = false;
  Position? _currentPosition;
  List<String> _capturedPhotos = [];
  List<String> _voiceNotes = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getCurrentLocation();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras.first, ResolutionPreset.high);
    await _cameraController.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _mobileAssetService.getAssetLocation();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final photoUrl = await _mobileAssetService.capturePhoto(widget.assetId);
      setState(() {
        _capturedPhotos.add(photoUrl);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing photo: $e')),
      );
    }
  }

  Future<void> _toggleVoiceRecording() async {
    try {
      if (_isRecording) {
        final voiceUrl = await _mobileAssetService.recordVoiceNote(widget.assetId);
        setState(() {
          _voiceNotes.add(voiceUrl);
          _isRecording = false;
        });
      } else {
        setState(() {
          _isRecording = true;
        });
        // Voice recording starts automatically in the service
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error with voice recording: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capture Asset: ${widget.assetName}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_cameraController.value.isInitialized)
              Container(
                height: 300,
                child: CameraPreview(_cameraController),
              ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.camera),
                    label: Text('Capture Photo'),
                    onPressed: _capturePhoto,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    label: Text(_isRecording ? 'Stop Recording' : 'Record Voice Note'),
                    onPressed: _toggleVoiceRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : null,
                    ),
                  ),
                  if (_currentPosition != null) ...[
                    SizedBox(height: 16),
                    Text(
                      'Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  SizedBox(height: 16),
                  Text(
                    'Captured Photos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _capturedPhotos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Image.network(_capturedPhotos[index]),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Voice Notes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _voiceNotes.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(Icons.audio_file),
                        title: Text('Voice Note ${index + 1}'),
                        trailing: IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () {
                            // Implement audio playback
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
} 