import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
void showTermsAndPrivacyDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _TermsAndPrivacyDialog();
    },
  );
}

class _TermsAndPrivacyDialog extends StatefulWidget {
  @override
  State<_TermsAndPrivacyDialog> createState() => _TermsAndPrivacyDialogState();
}

class _TermsAndPrivacyDialogState extends State<_TermsAndPrivacyDialog> {
  String _selectedLang = 'en';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xff185794),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Terms & Privacy",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownButton<String>(
                    dropdownColor: Colors.white,
                    value: _selectedLang,
                    style: const TextStyle(color: Colors.black),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('EN')),
                      DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
                      DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
                    ],
                    onChanged: (lang) => setState(() => _selectedLang = lang!),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: _TermsLocalizedContent(lang: _selectedLang),
                ),
              ),
            ),

            const Divider(),

            // "I Agree" Button
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff185794),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () async{
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('hasAgreedToTerms', true);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "I Agree",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsLocalizedContent extends StatelessWidget {
  final String lang;
  const _TermsLocalizedContent({required this.lang});

  TextStyle get headingStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xff185794),
  );

  TextStyle get bodyStyle => const TextStyle(fontSize: 14, height: 1.5);

  Map<String, Map<String, String>> get localized => {
    'en': {
      'agreement': 'By accessing this app, you accept our terms of use. If you do not agree with any part of these terms, please refrain from using the app.',
      'privacy': 'We respect your privacy and are committed to protecting it. We may collect your name, email, phone number, and professional details to provide better services.',
      'medical': 'This app provides access to oncology and specialty medicine information. It is intended for professional reference only and should not replace medical advice from a licensed provider.',
      'ip': 'All content, logos, and graphics are owned by PFIPL and protected under copyright laws. Unauthorized use is prohibited.',
      'usage': 'Content is not for redistribution or resale. You agree not to misuse the platform or data presented in the app.',
      'disclaimers': '• Product data taken from web sources\n• At most care is taken for accuracy\n• PFIPL is not responsible for any source errors',
      'updates': 'We may update these terms and privacy policies. Major updates will be notified within the app.',
      'contact': 'Email: privacy@pharmafive.com\nPhone: +91-XXXXXXXXXX'
    },
    'ta': {
      'agreement': 'இந்த பயன்பாட்டை அணுகுவதன் மூலம், நீங்கள் நிபந்தனைகளை ஏற்கிறீர்கள். ஏதேனும் ஒப்புக்கொள்ள முடியாவிட்டால், தயவுசெய்து பயன்பாட்டை பயன்படுத்த வேண்டாம்.',
      'privacy': 'உங்கள் தனியுரிமையை மதிக்கிறோம். உங்கள் பெயர், மின்னஞ்சல், தொலைபேசி எண் போன்ற விவரங்களை சேகரிக்கலாம்.',
      'medical': 'இந்த செயலி புற்றுநோய் மருந்துகள் உள்ளிட்ட மருத்துவத் தகவல்களை வழங்குகிறது. இது வைத்தியரின் ஆலோசனையை மாற்றாது.',
      'ip': 'எல்லா உள்ளடக்கமும் PFIPL-க்கு உரிமைப்பட்டவை. அனுமதியின்றி பயன்படுத்தக்கூடாது.',
      'usage': 'இந்த தகவல்களை மறுபயன்படுத்த அனுமதி இல்லை.',
      'disclaimers': '• தயாரிப்பு தரவுகள் இணையத்திலிருந்து பெறப்பட்டவை\n• அதிக கவனத்துடன் தரப்பட்டவை\n• தவறுகளுக்குப் PFIPL பொறுப்பல்ல',
      'updates': 'இந்த நிபந்தனைகள் மாற்றப்படலாம். முக்கிய மாற்றங்கள் செயலியில் அறிவிக்கப்படும்.',
      'contact': 'மின்னஞ்சல்: privacy@pharmafive.com\nதொலைபேசி: +91-XXXXXXXXXX'
    },
    'hi': {
      'agreement': 'इस ऐप का उपयोग करके, आप हमारी शर्तों से सहमत होते हैं। यदि आप सहमत नहीं हैं, तो कृपया ऐप का उपयोग न करें।',
      'privacy': 'हम आपकी गोपनीयता का सम्मान करते हैं। हम आपके नाम, ईमेल, और फ़ोन नंबर जैसी जानकारी एकत्र कर सकते हैं।',
      'medical': 'यह ऐप कैंसर और विशेष दवाओं की जानकारी देता है, जो केवल रेफरेंस के लिए है।',
      'ip': 'सभी सामग्री PFIPL की संपत्ति है। अनाधिकृत उपयोग निषिद्ध है।',
      'usage': 'आप इस सामग्री का पुनर्वितरण नहीं कर सकते।',
      'disclaimers': '• उत्पाद डेटा वेब स्रोतों से लिया गया है\n• सटीकता का ध्यान रखा गया है\n• PFIPL स्रोत त्रुटियों के लिए ज़िम्मेदार नहीं है',
      'updates': 'हम इन शर्तों को समय-समय पर अपडेट कर सकते हैं। महत्वपूर्ण बदलाव ऐप में बताए जाएंगे।',
      'contact': 'ईमेल: privacy@pharmafive.com\nफोन: +91-XXXXXXXXXX'
    }
  };

  @override
  Widget build(BuildContext context) {
    final data = localized[lang]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("1. User Agreement", style: headingStyle),
        Text(data['agreement']!, style: bodyStyle),
        const SizedBox(height: 16),

        Text("2. Privacy Policy", style: headingStyle),
        Text(data['privacy']!, style: bodyStyle),
        const SizedBox(height: 16),

        Text("3. Use of Medical Data", style: headingStyle),
        Text(data['medical']!, style: bodyStyle),
        const SizedBox(height: 16),

        Text("4. Intellectual Property", style: headingStyle),
        Text(data['ip']!, style: bodyStyle),
        const SizedBox(height: 16),

        Text("5. App Usage Limitations", style: headingStyle),
        Text(data['usage']!, style: bodyStyle),
        const SizedBox(height: 16),

        Text("6. Disclaimers", style: headingStyle),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xfffff4e5),
            border: Border(left: BorderSide(color: Color(0xffffc107), width: 4)),
          ),
          child: Text(data['disclaimers']!, style: bodyStyle),
        ),

        Text("7. Changes to This Policy", style: headingStyle),
        Text(data['updates']!, style: bodyStyle),
        const SizedBox(height: 16),

        Text("8. Contact", style: headingStyle),
        Text(data['contact']!, style: bodyStyle),
        const SizedBox(height: 20),

        const Divider(),
        const Center(
          child: Text(
            "© 2025 Pharma Five International Pvt. Ltd.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}*/

void showTermsAndPrivacyDialog(BuildContext context, String currentAppVersion) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _TermsAndPrivacyDialog(currentAppVersion: currentAppVersion);
    },
  );
}

class _TermsAndPrivacyDialog extends StatefulWidget {
  final String currentAppVersion;
  const _TermsAndPrivacyDialog({required this.currentAppVersion});

  @override
  State<_TermsAndPrivacyDialog> createState() => _TermsAndPrivacyDialogState();
}

class _TermsAndPrivacyDialogState extends State<_TermsAndPrivacyDialog> {
  bool _dontShowAgain = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xff185794),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      "Terms & Privacy",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: _TermsContentEnglish(),
                ),
              ),
            ),

            CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text("Don't show this again", style: TextStyle(fontSize: 14)),
              value: _dontShowAgain,
              onChanged: (val) => setState(() => _dontShowAgain = val ?? true),
            ),

            const Divider(),

            // "I Agree" Button
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff185794),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  if (_dontShowAgain) {
                    await prefs.setString('agreedTermsVersion', widget.currentAppVersion);
                  }
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "I Agree",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsContentEnglish extends StatelessWidget {
  const _TermsContentEnglish();

  TextStyle get headingStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xff185794),
  );

  TextStyle get bodyStyle => const TextStyle(fontSize: 14, height: 1.5);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("1. User Agreement", style: headingStyle),
        Text(
          "By accessing this app, you accept our terms of use. If you do not agree with any part of these terms, please refrain from using the app.",
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        Text("2. Privacy Policy", style: headingStyle),
        Text(
          "We respect your privacy and are committed to protecting it. We may collect your name, email, phone number, and professional details to provide better services.",
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        Text("3. Use of Medical Data", style: headingStyle),
        Text(
          "This app provides access to oncology and specialty medicine information. It is intended for professional reference only and should not replace medical advice from a licensed provider.",
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        Text("4. Intellectual Property", style: headingStyle),
        Text(
          "All content, logos, and graphics are owned by PFIPL and protected under copyright laws. Unauthorized use is prohibited.",
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        Text("5. App Usage Limitations", style: headingStyle),
        Text(
          "Content is not for redistribution or resale. You agree not to misuse the platform or data presented in the app.",
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        Text("6. Disclaimers", style: headingStyle),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xfffff4e5),
            border: Border(left: BorderSide(color: Color(0xffffc107), width: 4)),
          ),
          child: const Text(
            "• Product data taken from web sources\n• At most care is taken for accuracy\n• PFIPL is not responsible for any source errors",
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        Text("7. Changes to This Policy", style: headingStyle),
        Text(
          "We may update these terms and privacy policies. Major updates will be notified within the app.",
          style: bodyStyle,
        ),
        const SizedBox(height: 16),
        Text("8. Contact", style: headingStyle),
        Text(
          "Email: info@pharmafive.org\nPhone: +91-6374297988",
          style: bodyStyle,
        ),
        const SizedBox(height: 20),
        const Divider(),
        const Center(
          child: Text(
            "© 2025 Pharma Five International Pvt. Ltd.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
