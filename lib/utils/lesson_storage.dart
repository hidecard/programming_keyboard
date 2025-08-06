import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LessonStorage {
  static Future<Map<String, dynamic>> loadLessons() async {
    if (kIsWeb) {
      // Web: asset ထဲက JSON ကိုသာ ဖတ်နိုင်
      final assetString = await rootBundle.loadString('assets/lessons.json');
      return json.decode(assetString);
    } else {
      // Desktop/Mobile: local file သုံး
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/lessons.json');
      if (!(await file.exists())) {
        final assetString = await rootBundle.loadString('assets/lessons.json');
        await file.writeAsString(assetString);
      }
      final jsonString = await file.readAsString();
      return json.decode(jsonString);
    }
  }

  static Future<void> saveLessons(Map<String, dynamic> lessons) async {
    if (kIsWeb) {
      // Web: asset overwrite မလုပ်နိုင်
      // localStorage သီးသန့်သုံးချင်ရင် js interop သုံးရမယ်
      // ဒီနေရာမှာ မလုပ်နိုင်သော်လည်း error မပေးအောင် ထားပါ
      return;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/lessons.json');
      await file.writeAsString(json.encode(lessons));
    }
  }
}
