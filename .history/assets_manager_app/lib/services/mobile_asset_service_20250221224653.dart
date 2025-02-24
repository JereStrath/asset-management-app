import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';

class MobileAssetService {
  static final MobileAssetService _instance = MobileAssetService._internal();
  factory MobileAssetService() => _instance;
  MobileAssetService._internal();

  final _storage = FirebaseStorage.instance;
  final _record = Record();
  final _uuid = Uuid();

  Future<String> capturePhoto(String assetId) async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    final controller = CameraController(camera, ResolutionPreset.high);
    await controller.initialize();

    final image = await controller.takePicture();
    final fileName = 'assets/$assetId/${_uuid.v4()}.jpg';
    
    final ref = _storage.ref().child(fileName);
    await ref.putFile(File(image.path));
    
    return await ref.getDownloadURL();
  }

  Future<String> recordVoiceNote(String assetId) async {
    if (await _record.hasPermission()) {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/${_uuid.v4()}.m4a';
      
      await _record.start(path: filePath);
      // Record for maximum 2 minutes
      await Future.delayed(Duration(minutes: 2));
      final path = await _record.stop();

      final fileName = 'assets/$assetId/voice_notes/${_uuid.v4()}.m4a';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(File(path!));
      
      return await ref.getDownloadURL();
    }
    throw Exception('No permission to record audio');
  }

  Future<Position> getAssetLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition();
  }
} 