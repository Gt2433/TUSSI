import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('الرجاء كتابة كلمة مرور حسابك عند تشغيل السكربت.');
    print('Usage: dart run test/restore_admin.dart <YOUR_PASSWORD>');
    return;
  }
  
  final password = args[0];
  final email = 'hhcgjvhcnk@gmail.com';
  final apiKey = 'AIzaSyCtEPgAIoEY6rZpzYBAurutr-kCobJaaBI';
  
  print('جاري تسجيل الدخول للحصول على معرف المستخدم الخاص بك (UID)...');
  
  // 1. Sign in with Auth REST API to get UID
  final authUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey';
  final authResponse = await http.post(
    Uri.parse(authUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    }),
  );
  
  if (authResponse.statusCode != 200) {
    print('خطأ في تسجيل الدخول: ${authResponse.body}');
    return;
  }
  
  final authData = jsonDecode(authResponse.body);
  final uid = authData['localId'] as String;
  print('تم الحصول على معرف المستخدم (UID) بنجاح: $uid');
  
  // 2. Load Service Account details
  final saFile = File('serviceAccountJson.json');
  if (!saFile.existsSync()) {
    print('خطأ: لم يتم العثور على ملف serviceAccountJson.json في المجلد الرئيسي للبرنامج.');
    return;
  }
  
  final saJson = jsonDecode(saFile.readAsStringSync());
  final credentials = ServiceAccountCredentials.fromJson(saJson);
  final scopes = ['https://www.googleapis.com/auth/datastore'];
  
  print('جاري إنشاء اتصال آمن مع قاعدة البيانات باستخدام ملف الخدمة...');
  final client = await clientViaServiceAccount(credentials, scopes);
  
  final projectId = saJson['project_id'];
  final firestoreBaseUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  
  // 3. Create dummy shop
  print('جاري إنشاء محل وهمي (dummy_shop) في قاعدة البيانات...');
  final shopUrl = '$firestoreBaseUrl/shops/dummy_shop';
  final shopResponse = await client.patch(
    Uri.parse(shopUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'fields': {
        'id': {'stringValue': 'dummy_shop'},
        'name': {'stringValue': 'محل تجريبي وهمي'},
        'inviteCode': {'stringValue': 'FN-000000'},
        'isActive': {'booleanValue': true},
        'subscriptionExpiresAt': {
          'timestampValue': DateTime.now().add(const Duration(days: 365)).toUtc().toIso8601String()
        },
        'createdAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String()
        }
      }
    }),
  );
  
  if (shopResponse.statusCode != 200) {
    print('خطأ أثناء إنشاء المحل: ${shopResponse.body}');
    client.close();
    return;
  }
  print('تم إنشاء المحل الوهمي بنجاح!');
  
  // 4. Create/Restore super admin user document
  print('جاري استعادة حساب المدير العام وربطه بالمحل الوهمي...');
  final userUrl = '$firestoreBaseUrl/users/$uid';
  final userResponse = await client.patch(
    Uri.parse(userUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'fields': {
        'uid': {'stringValue': uid},
        'email': {'stringValue': email},
        'displayName': {'stringValue': 'المدير العام'},
        'role': {'stringValue': 'super_admin'},
        'shopId': {'stringValue': 'dummy_shop'},
        'createdAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String()
        }
      }
    }),
  );
  
  if (userResponse.statusCode != 200) {
    print('خطأ أثناء استعادة الحساب: ${userResponse.body}');
  } else {
    print('تهانينا! تم استعادة حسابك الشخصي وربطه بالمحل الوهمي بنجاح.');
    print('يمكنك الآن فتح التطبيق وتسجيل الدخول بشكل طبيعي.');
  }
  
  client.close();
}
