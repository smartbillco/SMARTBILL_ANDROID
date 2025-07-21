import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecorderService {

  final record = AudioRecorder();

  Future<String> startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    if (await record.hasPermission()) {
      await record.start(const RecordConfig(), path: path);
      return path;
    } else {
      throw Exception('Recording permission not granted');
    }
  }

  Future<String?> stopRecording() async {
    return await record.stop();  // returns path to recorded file
  }

}