import 'dart:convert';
import 'package:http/http.dart' as http;

/// Dedicated Universal AI Agent Service for TUSSI Application
/// Supports Gemini (AIzaSy...), Groq (gsk_...), and DeepSeek (sk-...) Keys automatically
class AiAssistantService {
  // Current active key provided by user
  static String activeApiKey = 'sk-4753d0f328ac4232a4eede48dba0e1a4';

  static const String _systemInstruction = '''
أنت المساعد الذكي الرسمي والوحيد لتطبيق TUSSI (TUSSI Fabric Management System).
مهمتك الأساسية هي شرح وتدريب المستخدمين على استخدام كل خصائص ومميزات تطبيق TUSSI بالتفصيل الممل والواضح.

قانون صارم لا يقبل الاستثناء:
- يُمنع منعاً باتاً الإجابة عن أي سؤال خارج نطاق تطبيق TUSSI أو إدارة الأقمشة والطلبيات والذمم داخل التطبيق.
- إذا سألك المستخدم عن أي موضوع خارجي (مثل: الطبخ، الطقس، البرمجة، معلومات عامة، سياسة، رياضة، إلخ)، يجب عليك الرد بلباقة بهذا النص بالضبط:
"أعتذر منك! أنا مساعد ذكي مخصص حصرياً لمساعدتك في استخدام تطبيق TUSSI وإدارة الطلبيات والأقمشة والذمم. كيف يمكنني مساعدتك في تطبيق TUSSI اليوم؟"

معلومات تطبيق TUSSI الكاملة التي تعرفها عن ظهر قلب:
1. الشاشة الرئيسية (Home Screen):
   ملخص الطلبيات، البحث، إحصائيات السداد والذمم، تنبيهات الإشعارات، وزر إضافة طلبية جديدة (+).
2. إضافة طلبية جديدة (New Order):
   تحديد المستلم والزبون، إضافة أنواع أقمشة بأسطواناتها وأطوالها (مثل: 50.5، 40، 60) والوحدة (متر m، كغ kg، ياردة yd)، تحديد السعر الفردي والإجمالي التلقائي، إضافة تسجيل صوتي (Voice Note) وحفظ مسودة (Draft).
3. مسح رمز QR وحفظ الفاتورة:
   مسح كود QR المطبوع على الطلبية بكاميرا الهاتف من شاشة الطلبيات، وتنزيل صورة الفاتورة تلقائياً في معرض الصور (Gallery) في هاتفك فور المسح.
4. تصدير فواتير PDF بالفرنسية:
   تصدير مستند A4 منظم باللغة الفرنسية (FACTURE OFFICIELLE DE COMMANDE DE TISSUS) يحتوي على تفاصيل الأقمشة والأسطوانات والإجماليات.
5. الذمم المالية والدفعات (Payments & Debts Screen):
   متابعة المبالغ غير المسددة ونسبة السداد، وزر تسجيل وتعديل الدفع فورياً.
6. سجل الطلبيات والبحث (Order History & Filter):
   تصفح الطلبيات المكتملة والملغاة والمسودات والبحث برقم الطلبية أو اسم الزبون.
7. الإعدادات واللغات (Settings & Language):
   دعم العربية والفرنسية والإنجليزية والوضع الداكن (Dark Mode).

أسلوبك في الإجابة:
- استعمل اللغة العربية الواضحة والمرتبة واستخدم الإيموجي والنقاط لتبسيط الشرح خطوة بخطوة.
- لا تستخدم علامات النجوم ** المزدوجة لتفادي مشاكل المحاذاة والتنسيق العربي.
''';

  static Future<String> askAssistant(String userQuestion) async {
    final key = activeApiKey.trim();

    // 1. Google Gemini API Key (starts with AIzaSy)
    if (key.startsWith('AIzaSy')) {
      try {
        final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key');
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({
                "system_instruction": {
                  "parts": [
                    {"text": _systemInstruction}
                  ]
                },
                "contents": [
                  {
                    "role": "user",
                    "parts": [
                      {"text": userQuestion}
                    ]
                  }
                ],
                "generationConfig": {"temperature": 0.3, "maxOutputTokens": 1000}
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null && text.toString().trim().isNotEmpty) {
            return _cleanText(text.toString().trim());
          }
        } else {
          print('Gemini API Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Gemini Request Error: $e');
      }
    }

    // 2. Groq Cloud API Key (starts with gsk_)
    if (key.startsWith('gsk_')) {
      try {
        final response = await http
            .post(
              Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': 'Bearer $key',
              },
              body: jsonEncode({
                "model": "llama-3.3-70b-versatile",
                "messages": [
                  {"role": "system", "content": _systemInstruction},
                  {"role": "user", "content": userQuestion}
                ],
                "temperature": 0.3
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']['content'];
            if (content != null && content.toString().trim().isNotEmpty) {
              return _cleanText(content.toString().trim());
            }
          }
        } else {
          print('Groq API Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Groq Request Error: $e');
      }
    }

    // 3. DeepSeek API Key (starts with sk-)
    if (key.startsWith('sk-')) {
      try {
        final response = await http
            .post(
              Uri.parse('https://api.deepseek.com/chat/completions'),
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': 'Bearer $key',
              },
              body: jsonEncode({
                "model": "deepseek-chat",
                "messages": [
                  {"role": "system", "content": _systemInstruction},
                  {"role": "user", "content": userQuestion}
                ],
                "temperature": 0.3,
                "max_tokens": 1000,
                "stream": false
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']['content'];
            if (content != null && content.toString().trim().isNotEmpty) {
              return _cleanText(content.toString().trim());
            }
          }
        }
      } catch (e) {
        print('DeepSeek Request Error: $e');
      }
    }

    // 4. Instant Live LLM Fallback (Pollinations GET Engine)
    try {
      final promptEncoded = Uri.encodeComponent(userQuestion);
      final systemEncoded = Uri.encodeComponent(_systemInstruction);
      final getUrl = Uri.parse('https://text.pollinations.ai/$promptEncoded?system=$systemEncoded');

      final getResp = await http.get(getUrl).timeout(const Duration(seconds: 10));

      if (getResp.statusCode == 200 && getResp.body.trim().isNotEmpty) {
        return _cleanText(utf8.decode(getResp.bodyBytes));
      }
    } catch (e) {
      print('Fallback Live AI Error: $e');
    }

    // 5. Guaranteed Knowledge Base Fallback
    return _getOfflineFallbackResponse(userQuestion);
  }

  static String _cleanText(String input) {
    return input.replaceAll('**', '').trim();
  }

  static String _getOfflineFallbackResponse(String question) {
    final q = question.toLowerCase();

    if (!q.contains('تطبيق') &&
        !q.contains('طلبية') &&
        !q.contains('طلب') &&
        !q.contains('قماش') &&
        !q.contains('سكان') &&
        !q.contains('qr') &&
        !q.contains('pdf') &&
        !q.contains('ذمم') &&
        !q.contains('دفع') &&
        !q.contains('استوديو') &&
        !q.contains('صورة') &&
        !q.contains('لغة') &&
        !q.contains('مسودة') &&
        !q.contains('توسي') &&
        !q.contains('tussi') &&
        !q.contains('كيف') &&
        !q.contains('شرح') &&
        !q.contains('استخدم') &&
        !q.contains('hi') &&
        !q.contains('hello')) {
      return "أعتذر منك! أنا مساعد ذكي مخصص حصرياً لمساعدتك في استخدام تطبيق TUSSI وإدارة الطلبيات والأقمشة والذمم. كيف يمكنني مساعدتك في التطبيق اليوم؟";
    }

    if (q.contains('سكان') || q.contains('qr') || q.contains('رمز')) {
      return "📷 كيفية مسح رمز QR وحفظ الفاتورة في تطبيق TUSSI:\n\n"
          "1. افتح شاشة الطلبيات من القائمة السفلى.\n"
          "2. اضغط على أيقونة المسح الضوئي في الأعلى.\n"
          "3. وجّه كاميرا الهاتف نحو رمز الـ QR المطبوع على الطلبية.\n"
          "4. سيقوم تطبيق TUSSI بحفظ صورة الفاتورة فوراً وتلقائياً في معرض الصور (Gallery) في هاتفك! ✨";
    }

    if (q.contains('pdf') || q.contains('فاتورة') || q.contains('تصدير')) {
      return "📄 كيفية تصدير فاتورة PDF بالفرنسية:\n\n"
          "1. ادخل إلى شاشة الطلبيات أو سجل الطلبيات.\n"
          "2. اضغط على زر المشاركة / المستند في بطاقة الطلبية.\n"
          "3. اختر تصدير كـ PDF.\n"
          "4. يتم توليد فاتورة رسمية باللغة الفرنسية (FACTURE OFFICIELLE DE COMMANDE DE TISSUS) تحتوي على التفاصيل المالية للأقمشة والأسطوانات! 🇫🇷";
    }

    if (q.contains('ذمم') || q.contains('دفع') || q.contains('دين') || q.contains('متبقي')) {
      return "💳 متابعة وتسجيل الذمم المالية:\n\n"
          "1. انتقل إلى شاشة الذمم المالية (Payments).\n"
          "2. ستجد قائمة بكل الطلبيات التي بها مبالغ متبقية مع شريط نسبة السداد.\n"
          "3. اضغط على تسجيل / تعديل الدفع لإدخال المبلغ الجديد المدفوع.\n"
          "4. يتم تحديث الدين والمبلغ المتبقي فوراً في الوقت الفعلي! 📊";
    }

    return "أهلاً بك في مساعد TUSSI الذكي! ✨\n\n"
        "أنا مجيبك الخاص لكل ما يتعلق بتطبيق TUSSI:\n"
        "• كيفية إنشاء وتعديل طلبية أقمشة جديدة\n"
        "• مسح رمز الـ QR وتنزيل صورة الفاتورة في المعرض\n"
        "• تصدير فواتير الـ PDF الرسمية باللغة الفرنسية\n"
        "• متابعة وتسجيل الذمم والدفعات المالية\n\n"
        "تفضل بسؤالك وسأشرح لك الخطوات بالتفصيل!";
  }
}
