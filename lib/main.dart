
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';

void main() => runApp(const VoiceTranslatorApp());

const languages = <Language>[
  Language('العربية', 'ar-EG', 'ar'),
  Language('English', 'en-US', 'en'),
  Language('Français', 'fr-FR', 'fr'),
  Language('Español', 'es-ES', 'es'),
  Language('Deutsch', 'de-DE', 'de'),
  Language('Italiano', 'it-IT', 'it'),
  Language('Türkçe', 'tr-TR', 'tr'),
  Language('Português', 'pt-PT', 'pt'),
  Language('Русский', 'ru-RU', 'ru'),
  Language('中文', 'zh-CN', 'zh-cn'),
  Language('日本語', 'ja-JP', 'ja'),
  Language('हिन्दी', 'hi-IN', 'hi'),
  Language('한국어', 'ko-KR', 'ko'),
  Language('Nederlands', 'nl-NL', 'nl'),
  Language('Ελληνικά', 'el-GR', 'el'),
  Language('Polski', 'pl-PL', 'pl'),
  Language('Українська', 'uk-UA', 'uk'),
  Language('فارسی', 'fa-IR', 'fa'),
  Language('اردو', 'ur-PK', 'ur'),
  Language('ไทย', 'th-TH', 'th'),
  Language('Tiếng Việt', 'vi-VN', 'vi'),
  Language('Bahasa Indonesia', 'id-ID', 'id'),
  Language('বাংলা', 'bn-BD', 'bn'),
  Language('עברית', 'he-IL', 'iw'),
];

class Language {
  final String name;
  final String locale;
  final String code;

  const Language(this.name, this.locale, this.code);
}

/// Common Egyptian colloquial words/particles mapped to their Modern
/// Standard Arabic equivalent. Google Translate's Arabic model is built
/// around MSA, so a handful of very frequent dialect words (negation,
/// demonstratives, question words...) can come out wrong or literal when
/// translated as-is. This is a small, curated list — not a full dialect
/// translator — meant to fix the most common everyday words before they
/// reach the translation engine.
const Map<String, String> egyptianColloquialToStandardArabic = {
  'عايز': 'أريد',
  'عايزة': 'أريد',
  'عاوز': 'أريد',
  'عاوزة': 'أريد',
  'عايزين': 'نريد',
  'عاوزين': 'نريد',
  'مش': 'ليس',
  'مانيش': 'لست',
  'ازيك': 'كيف حالك',
  'إزيك': 'كيف حالك',
  'ازيكم': 'كيف حالكم',
  'فين': 'أين',
  'امتى': 'متى',
  'إمتى': 'متى',
  'ليه': 'لماذا',
  'كده': 'هكذا',
  'كدا': 'هكذا',
  'خالص': 'تماما',
  'يلا': 'هيا',
  'يالا': 'هيا',
  'لسه': 'ما زال',
  'بقى': 'إذن',
  'بقا': 'إذن',
  'علشان': 'لأن',
  'عشان': 'لأن',
  'عاشان': 'لأن',
  'حاجة': 'شيء',
  'حاجه': 'شيء',
  'كتير': 'كثير',
  'كتيرة': 'كثيرة',
  'شوية': 'قليلا',
  'شويه': 'قليلا',
  'دلوقتي': 'الآن',
  'دلوقت': 'الآن',
  'امبارح': 'أمس',
  'إمبارح': 'أمس',
  'بكرة': 'غدا',
  'بكره': 'غدا',
  'ايه': 'ماذا',
  'إيه': 'ماذا',
  'ازاي': 'كيف',
  'إزاي': 'كيف',
  'مين': 'من',
  'تمام': 'حسنا',
  'خلاص': 'انتهى',
  'معلش': 'لا بأس',
  'معلّش': 'لا بأس',
  'اهو': 'ها هو',
  'أهو': 'ها هو',
  'اهي': 'ها هي',
  'أهي': 'ها هي',
  'اوي': 'جدا',
  'أوي': 'جدا',
  'جامد': 'ممتاز',
  'حلو': 'جميل',
  'وحش': 'سيء',
  'زي': 'مثل',
  'زى': 'مثل',
  'بتاع': 'الخاص بـ',
  'بتاعة': 'الخاصة بـ',
};

class VoiceTranslatorApp extends StatefulWidget {
  const VoiceTranslatorApp({super.key});

  @override
  State<VoiceTranslatorApp> createState() => _VoiceTranslatorAppState();
}

class _VoiceTranslatorAppState extends State<VoiceTranslatorApp> {
  ThemeMode _mode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('themeMode') ?? 'system';
    if (!mounted) return;
    setState(() {
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => ThemeMode.system,
      );
    });
  }

  Future<void> _setTheme(ThemeMode value) async {
    setState(() => _mode = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', value.name);
  }

  @override
  Widget build(BuildContext context) {
    const neonGreen = Color(0xFF39FF14);
    const neonMint = Color(0xFFB8FF9A);
    const neonLime = Color(0xFF7CFF00);
    const cyberGreen = Color(0xFF18D86F);
    const ink = Color(0xFF061006);
    const panelDark = Color(0xFF0A160A);
    const panelLight = Color(0xFFF8FFF6);
    const backgroundLight = Color(0xFFF0F9ED);
    const outlineDark = Color(0xFF315D31);

    final lightScheme = ColorScheme.light(
      primary: const Color(0xFF21A90F),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD9FFD0),
      onPrimaryContainer: const Color(0xFF062804),
      secondary: const Color(0xFF0D6B34),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFBDF7CF),
      onSecondaryContainer: const Color(0xFF03200D),
      tertiary: cyberGreen,
      onTertiary: Colors.black,
      surface: panelLight,
      onSurface: const Color(0xFF101810),
      surfaceContainerHighest: const Color(0xFFE7F3E4),
      onSurfaceVariant: const Color(0xFF53604F),
      outline: const Color(0xFF96A691),
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
    );

    final darkScheme = ColorScheme.dark(
      primary: neonGreen,
      onPrimary: Colors.black,
      primaryContainer: const Color(0xFF1B5E20),
      onPrimaryContainer: neonMint,
      secondary: neonLime,
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF123A16),
      onSecondaryContainer: const Color(0xFFD8FFD0),
      tertiary: cyberGreen,
      onTertiary: Colors.black,
      surface: panelDark,
      onSurface: const Color(0xFFEAF8E8),
      surfaceContainerHighest: const Color(0xFF0F200F),
      onSurfaceVariant: const Color(0xFFB8CDB4),
      outline: outlineDark,
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF3A0A08),
      onErrorContainer: const Color(0xFFFFDAD6),
    );

    final themeDisabledBackground = const Color(0xFF1A251A);
    final themeDisabledForeground = const Color(0xFF71806F);

    ButtonStyle neonButton({bool tonal = false}) {
      return FilledButton.styleFrom(
        backgroundColor: tonal ? const Color(0xFF143A15) : neonGreen,
        foregroundColor: tonal ? neonMint : Colors.black,
        disabledBackgroundColor: themeDisabledBackground,
        disabledForegroundColor: themeDisabledForeground,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 0;
          return tonal ? 0 : 4;
        }),
        shadowColor: WidgetStatePropertyAll(
          tonal ? Colors.transparent : neonGreen.withValues(alpha: 0.42),
        ),
      );
    }

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightScheme,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF101810),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: panelLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFDDEBDA)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F8F1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD8E3D6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD8E3D6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF21A90F), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(style: neonButton()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF17810C),
          side: const BorderSide(color: Color(0xFF8DCB84)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE8F5E5),
        selectedColor: const Color(0xFFD3FBCB),
        side: const BorderSide(color: Color(0xFFC9DFC6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: ink,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: neonMint,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: panelDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: neonGreen.withValues(alpha: 0.13)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1D0D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outlineDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outlineDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: neonGreen.withValues(alpha: 0.85), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(style: neonButton()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonMint,
          side: BorderSide(color: neonGreen.withValues(alpha: 0.52)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF0F260F),
        selectedColor: const Color(0xFF183B18),
        side: BorderSide(color: neonGreen.withValues(alpha: 0.18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Translator',
      themeMode: _mode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: TranslatorPage(
        themeMode: _mode,
        onThemeChanged: _setTheme,
      ),
    );
  }
}

class TranslatorPage extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const TranslatorPage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();
  final _translator = GoogleTranslator();
  final _input = TextEditingController();
  final _historySearch = TextEditingController();

  final _history = <TranslationRecord>[];

  Language _from = languages[0];
  Language _to = languages[1];

  String _output = '';
  String _historyQuery = '';
  String? _error;

  bool _listening = false;
  bool _busy = false;
  bool _speechAvailable = false;
  bool _liveMode = false;
  bool _liveProcessing = false;
  bool _speaking = false;
  bool _autoSpeak = true;
  bool _liveSpeak = true;
  bool _favoritesOnly = false;

  final List<Map<String, String>> _ttsVoices = [];
  Map<String, String>? _selectedTtsVoice;
  bool _loadingVoices = false;

  double _speechRate = 0.46;
  Duration _livePause = const Duration(milliseconds: 1000);

  int _liveSessionId = 0;
  bool _liveSessionHadFinal = false;
  Timer? _liveRestartTimer;
  String _liveLastFinalText = '';

  @override
  void initState() {
    super.initState();
    _configureTts();
    _initializeSpeech();
    _loadHistory();
    _loadSettings().then((_) => _loadTtsVoices());

    _historySearch.addListener(() {
      if (!mounted) return;
      setState(() => _historyQuery = _historySearch.text.trim());
    });
  }

  Future<void> _configureTts() async {
    try {
      await _tts.setSpeechRate(_speechRate);
      await _tts.awaitSpeakCompletion(true);
      _tts.setStartHandler(() {
        if (mounted) setState(() => _speaking = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _speaking = false);
      });
    } catch (_) {
      // Keep the app usable even when a platform TTS feature is unavailable.
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fromCode = prefs.getString('fromLanguage') ?? 'ar';
      final toCode = prefs.getString('toLanguage') ?? 'en';
      final savedRate = prefs.getDouble('speechRate') ?? 0.46;
      final savedPause = prefs.getInt('livePauseMs') ?? 1000;
      final savedVoiceName = prefs.getString('ttsVoiceName');
      final savedVoiceLocale = prefs.getString('ttsVoiceLocale');
      final savedVoiceIdentifier = prefs.getString('ttsVoiceIdentifier');

      Language pickByCode(String code, Language fallback) {
        return languages.firstWhere(
          (language) => language.code == code,
          orElse: () => fallback,
        );
      }

      if (!mounted) return;
      setState(() {
        _from = pickByCode(fromCode, _from);
        _to = pickByCode(toCode, _to);
        _autoSpeak = prefs.getBool('autoSpeak') ?? true;
        _liveSpeak = prefs.getBool('liveSpeak') ?? true;
        _speechRate = savedRate.clamp(0.20, 0.80);
        _livePause = Duration(milliseconds: savedPause.clamp(600, 2000));
        if (savedVoiceName != null && savedVoiceLocale != null) {
          _selectedTtsVoice = {
            'name': savedVoiceName,
            'locale': savedVoiceLocale,
            if (savedVoiceIdentifier != null && savedVoiceIdentifier.isNotEmpty)
              'identifier': savedVoiceIdentifier,
          };
        }
      });
      await _tts.setSpeechRate(_speechRate);
      await _applySelectedTtsVoice();
    } catch (_) {
      // Defaults are fine.
    }
  }

  Future<void> _persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fromLanguage', _from.code);
    await prefs.setString('toLanguage', _to.code);
    await prefs.setBool('autoSpeak', _autoSpeak);
    await prefs.setBool('liveSpeak', _liveSpeak);
    await prefs.setDouble('speechRate', _speechRate);
    await prefs.setInt('livePauseMs', _livePause.inMilliseconds);
    final voice = _selectedTtsVoice;
    if (voice == null) {
      await prefs.remove('ttsVoiceName');
      await prefs.remove('ttsVoiceLocale');
      await prefs.remove('ttsVoiceIdentifier');
    } else {
      await prefs.setString('ttsVoiceName', voice['name'] ?? '');
      await prefs.setString('ttsVoiceLocale', voice['locale'] ?? '');
      final identifier = voice['identifier'];
      if (identifier == null || identifier.isEmpty) {
        await prefs.remove('ttsVoiceIdentifier');
      } else {
        await prefs.setString('ttsVoiceIdentifier', identifier);
      }
    }
  }

  String _voiceLanguageCode(String locale) => locale.toLowerCase().split('-').first.split('_').first;

  Future<void> _loadTtsVoices() async {
    if (_loadingVoices) return;
    _loadingVoices = true;
    try {
      final raw = await _tts.getVoices;
      final parsed = <Map<String, String>>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is! Map) continue;
          final name = item['name']?.toString().trim() ?? '';
          final locale = item['locale']?.toString().trim() ?? '';
          if (name.isEmpty || locale.isEmpty) continue;
          final voice = <String, String>{'name': name, 'locale': locale};
          final identifier = item['identifier']?.toString().trim();
          if (identifier != null && identifier.isNotEmpty) voice['identifier'] = identifier;
          if (!parsed.any((v) => v['name'] == name && v['locale'] == locale && v['identifier'] == voice['identifier'])) {
            parsed.add(voice);
          }
        }
      }

      parsed.sort((a, b) {
        final targetCode = _to.code.toLowerCase().split('-').first;
        final aMatch = _voiceLanguageCode(a['locale'] ?? '') == targetCode ? 0 : 1;
        final bMatch = _voiceLanguageCode(b['locale'] ?? '') == targetCode ? 0 : 1;
        if (aMatch != bMatch) return aMatch.compareTo(bMatch);
        return (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase());
      });

      if (!mounted) return;
      setState(() {
        _ttsVoices
          ..clear()
          ..addAll(parsed.take(200));
      });

      final selected = _selectedTtsVoice;
      if (selected != null) {
        if (_voiceLanguageCode(selected['locale'] ?? '') != _to.code.toLowerCase().split('-').first) {
          _selectedTtsVoice = null;
          await _persistSettings();
        } else {
          Map<String, String>? match;
          for (final voice in _ttsVoices) {
            if (voice['name'] == selected['name'] && voice['locale'] == selected['locale']) {
              match = voice;
              break;
            }
          }
          if (match != null) {
            _selectedTtsVoice = match;
            await _applySelectedTtsVoice();
          } else {
            _selectedTtsVoice = null;
            await _persistSettings();
          }
        }
      }
    } catch (_) {
      // Some web/device TTS engines expose no voice list. Keep default voice.
    } finally {
      _loadingVoices = false;
      if (mounted) setState(() {});
    }
  }

  List<Map<String, String>> get _voicesForTargetLanguage {
    final target = _to.code.toLowerCase().split('-').first;
    final matches = _ttsVoices.where((voice) => _voiceLanguageCode(voice['locale'] ?? '') == target).toList();
    return matches.isNotEmpty ? matches : List<Map<String, String>>.from(_ttsVoices);
  }

  Future<void> _applySelectedTtsVoice() async {
    final voice = _selectedTtsVoice;
    if (voice == null) return;
    try {
      final payload = <String, String>{
        'name': voice['name'] ?? '',
        'locale': voice['locale'] ?? '',
      };
      final identifier = voice['identifier'];
      if (identifier != null && identifier.isNotEmpty) payload['identifier'] = identifier;
      await _tts.setVoice(payload);
    } catch (_) {
      // Fall back silently to the platform's default voice.
    }
  }

  Future<void> _selectTtsVoice(Map<String, String>? voice) async {
    setState(() => _selectedTtsVoice = voice);
    await _applySelectedTtsVoice();
    await _persistSettings();
  }

  Future<void> _previewTtsVoice(Map<String, String> voice) async {
    final text = _to.code == 'ar' ? 'مرحباً، هذا اختبار للصوت.' : 'Hello, this is a voice test.';
    try {
      await _tts.stop();
      await _tts.setLanguage(_to.locale);
      final payload = <String, String>{'name': voice['name'] ?? '', 'locale': voice['locale'] ?? ''};
      final identifier = voice['identifier'];
      if (identifier != null && identifier.isNotEmpty) payload['identifier'] = identifier;
      await _tts.setVoice(payload);
      await _tts.setSpeechRate(_speechRate);
      await _tts.speak(text);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تشغيل اختبار الصوت.');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('translationHistory');
      if (saved == null || saved.isEmpty) return;

      final decoded = jsonDecode(saved) as List<dynamic>;
      final records = decoded
          .map(
            (item) => TranslationRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _history
          ..clear()
          ..addAll(records.take(100));
      });
    } catch (_) {
      // Ignore invalid saved history.
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'translationHistory',
        jsonEncode(_history.map((record) => record.toJson()).toList()),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذر حفظ سجل الترجمات على هذا الجهاز.');
      }
    }
  }

  Future<void> _initializeSpeech() async {
    try {
      final ok = await _speech.initialize(
        options: [stt.SpeechToText.webDoNotAggregate],
        onStatus: (status) {
          if (!mounted) return;

          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);

            if (_liveMode && !_liveProcessing && !_liveSessionHadFinal) {
              _scheduleLiveRestart();
            }
          }
        },
        onError: (error) {
          if (!mounted) return;

          // "aborted" fires whenever our own code deliberately calls
          // _speech.stop() (to hand the recognized sentence off to
          // translation, or to start the next listening session) — it's
          // expected, not a real failure. Treating it as one was causing a
          // second, competing restart on top of the one our own code
          // already schedules, which never gave recognition a real chance
          // to capture speech.
          if (error.errorMsg.toLowerCase().contains('abort')) {
            return;
          }

          setState(() {
            _listening = false;
            _error = error.errorMsg;
          });

          if (_liveMode && !_liveProcessing) {
            _scheduleLiveRestart();
          }
        },
      );

      if (mounted) {
        setState(() => _speechAvailable = ok);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'التعرف على الكلام غير متاح في هذه البيئة.';
        });
      }
    }
  }

  Future<void> _listen() async {
    if (_listening && !_liveMode) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    if (_liveMode) {
      return;
    }

    await _startManualListening();
  }

  Future<void> _startManualListening() async {
    if (!_speechAvailable) await _initializeSpeech();

    if (!_speechAvailable) {
      if (mounted) {
        setState(() {
          _error = 'الميكروفون أو التعرف على الكلام غير متاح على هذا الجهاز.';
        });
      }
      return;
    }

    setState(() {
      _listening = true;
      _liveMode = false;
      _error = null;
    });

    try {
      await _speech.listen(
        localeId: _from.locale,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          pauseFor: const Duration(seconds: 2),
        ),
        onResult: (result) {
          if (!mounted) return;

          final recognized = result.recognizedWords.trim();

          setState(() {
            _input.value = TextEditingValue(
              text: recognized,
              selection: TextSelection.collapsed(
                offset: recognized.length,
              ),
            );
          });

          if (result.finalResult) {
            _translate();
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _listening = false;
          _error = 'تعذر بدء الاستماع. تحقق من إذن الميكروفون.';
        });
      }
    }
  }

  Future<void> _toggleLiveTranslation() async {
    if (_liveMode) {
      await _stopLiveTranslation();
      return;
    }

    await _startLiveTranslation();
  }

  Future<void> _startLiveTranslation() async {
    if (!_speechAvailable) await _initializeSpeech();

    if (!_speechAvailable) {
      if (mounted) {
        setState(() {
          _error =
              'لا يدعم الجهاز أو المتصفح التعرف على الكلام. يمكنك كتابة النص يدويًا.';
        });
      }
      return;
    }

    await _stopTts();

    _liveRestartTimer?.cancel();
    _liveRestartTimer = null;

    _liveSessionId++;
    _liveSessionHadFinal = false;
    _liveProcessing = false;
    _liveMode = true;
    _liveLastFinalText = '';

    if (mounted) {
      setState(() {
        _listening = true;
        _error = null;
        _input.clear();
      });
    }

    await _startLiveSpeechSession(_liveSessionId);
  }

  Future<void> _startLiveSpeechSession(int sessionId) async {
    if (!_liveMode || sessionId != _liveSessionId) return;

    _liveRestartTimer?.cancel();
    _liveRestartTimer = null;
    _liveSessionHadFinal = false;

    try {
      await _speech.stop();

      await _speech.listen(
        localeId: _from.locale,
        listenOptions: stt.SpeechListenOptions(
          partialResults: false,
          cancelOnError: true,
          pauseFor: _livePause,
          listenFor: const Duration(minutes: 1),
        ),
        onResult: (result) {
          if (!mounted || !_liveMode || sessionId != _liveSessionId) {
            return;
          }

          final recognized = result.recognizedWords.trim();
          if (recognized.isEmpty) return;

          setState(() {
            _input.value = TextEditingValue(
              text: recognized,
              selection: TextSelection.collapsed(
                offset: recognized.length,
              ),
            );
          });

          if (result.finalResult && !_liveSessionHadFinal) {
            _liveSessionHadFinal = true;

            final newPortion = _newPortionOfLiveTranscript(recognized);
            _liveLastFinalText = recognized;

            if (newPortion.isEmpty) {
              // Nothing new was actually said (engine re-reported the
              // previous sentence) — just keep listening for the next one.
              if (mounted && _liveMode && sessionId == _liveSessionId) {
                _scheduleLiveRestart();
              }
            } else {
              _translateLive(
                newPortion,
                sessionId: sessionId,
              );
            }
          }
        },
      );

      if (mounted &&
          _liveMode &&
          sessionId == _liveSessionId &&
          _speech.isListening) {
        setState(() => _listening = true);
      }
    } catch (_) {
      if (!mounted || !_liveMode || sessionId != _liveSessionId) return;

      setState(() {
        _listening = false;
        _error = 'تعذر بدء جلسة الترجمة الفورية.';
      });

      _scheduleLiveRestart();
    }
  }

  void _scheduleLiveRestart() {
    if (!_liveMode || _liveProcessing || _liveRestartTimer != null) {
      return;
    }

    final sessionId = ++_liveSessionId;
    _liveSessionHadFinal = false;

    _liveRestartTimer = Timer(
      const Duration(milliseconds: 300),
      () async {
        _liveRestartTimer = null;

        if (!mounted || !_liveMode || sessionId != _liveSessionId) {
          return;
        }

        await _startLiveSpeechSession(sessionId);

        if (mounted &&
            _liveMode &&
            sessionId == _liveSessionId &&
            _speech.isListening) {
          setState(() => _listening = true);
        }
      },
    );
  }

  Future<void> _stopLiveTranslation() async {
    _liveMode = false;
    _liveProcessing = false;
    _liveSessionId++;
    _liveSessionHadFinal = false;
    _liveLastFinalText = '';

    _liveRestartTimer?.cancel();
    _liveRestartTimer = null;

    await _speech.stop();
    await _stopTts();

    if (mounted) {
      setState(() {
        _listening = false;
        _error = null;
      });
    }
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[.,!?;:،؟]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Rewrites frequent Egyptian colloquial words in [text] to their Modern
  /// Standard Arabic equivalent using [egyptianColloquialToStandardArabic],
  /// so the translation engine (which is built around MSA) has a better
  /// chance of producing an accurate result. Only applied when translating
  /// from Arabic; the original text is left untouched for display/history.
  String _prepareForTranslation(String text) {
    if (_from.code != 'ar' || text.trim().isEmpty) return text;

    return text.splitMapJoin(
      RegExp(r'\S+'),
      onMatch: (match) {
        final token = match[0]!;
        final wordMatch =
            RegExp(r'^([\u0600-\u06FF]+)([^\u0600-\u06FF]*)$').firstMatch(token);
        if (wordMatch == null) return token;

        final word = wordMatch.group(1)!;
        final suffix = wordMatch.group(2) ?? '';
        final replacement = egyptianColloquialToStandardArabic[word];
        return replacement == null ? token : '$replacement$suffix';
      },
    );
  }

  /// Some speech engines (notably in the browser) keep appending to
  /// `recognizedWords` across restarts instead of resetting per session, so a
  /// new sentence can arrive glued to the one we already translated. This
  /// strips that known prefix off, returning only the newly spoken part.
  String _newPortionOfLiveTranscript(String recognized) {
    final previous = _liveLastFinalText.trim();
    if (previous.isEmpty) return recognized;

    final normalizedPrev = _normalizeText(previous);
    final normalizedNew = _normalizeText(recognized);

    if (normalizedNew == normalizedPrev) return '';
    if (!normalizedNew.startsWith(normalizedPrev)) return recognized;

    final prevWordCount = previous.trim().split(RegExp(r'\s+')).length;
    final words = recognized.trim().split(RegExp(r'\s+'));
    if (words.length <= prevWordCount) return '';

    return words.sublist(prevWordCount).join(' ').trim();
  }

  Future<void> _translateLive(
    String text, {
    required int sessionId,
  }) async {
    final clean = text.trim();
    final normalized = _normalizeText(clean);

    if (normalized.isEmpty ||
        !_liveMode ||
        sessionId != _liveSessionId) {
      return;
    }

    _liveProcessing = true;
    final requestId = sessionId;

    try {
      await _speech.stop();

      final result = await _translator.translate(
        _prepareForTranslation(clean),
        from: _from.code,
        to: _to.code,
      );

      if (!mounted ||
          !_liveMode ||
          sessionId != _liveSessionId ||
          requestId != _liveSessionId) {
        _liveProcessing = false;
        return;
      }

      final translated = result.text.trim();

      setState(() {
        _output = translated;
        _error = null;
      });

      _addToHistory(
        clean,
        translated,
        saveImmediately: true,
      );

      if (_liveSpeak) {
        await _speakText(translated);
      }

      _liveProcessing = false;

      if (mounted && _liveMode && sessionId == _liveSessionId) {
        _scheduleLiveRestart();
      }
    } catch (_) {
      _liveProcessing = false;

      if (!mounted || !_liveMode) return;

      setState(() {
        _error =
            'تعذرت الترجمة الفورية. تحقق من الإنترنت وإعدادات الصوت.';
      });

      _scheduleLiveRestart();
    }
  }

  Future<void> _translate() async {
    final text = _input.text.trim();

    if (text.isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await _translator.translate(
        _prepareForTranslation(text),
        from: _from.code,
        to: _to.code,
      );

      if (!mounted) return;

      final translated = result.text.trim();

      setState(() {
        _output = translated;
      });

      _addToHistory(
        text,
        translated,
        saveImmediately: true,
      );

      if (_autoSpeak) {
        await _speakText(translated);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'تعذرت الترجمة. تحقق من الإنترنت أو جرّب نصًا آخر.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addToHistory(
    String original,
    String translated, {
    bool saveImmediately = false,
  }) {
    final record = TranslationRecord(
      original,
      translated,
      _from.name,
      _to.name,
      DateTime.now(),
      false,
    );

    setState(() {
      _history.insert(0, record);
      if (_history.length > 100) {
        _history.removeLast();
      }
    });

    if (saveImmediately) {
      _saveHistory();
    }
  }

  Future<void> _speakText(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await _tts.stop();
      await _tts.setLanguage(_to.locale);
      await _applySelectedTtsVoice();
      await _tts.setSpeechRate(_speechRate);
      await _tts.speak(text);
      // awaitSpeakCompletion isn't reliably honored on every platform
      // (notably Flutter Web/Safari), so also wait on the _speaking flag
      // itself — it's driven by the TTS start/completion/cancel/error
      // handlers — before letting the caller move on (e.g. restart the
      // microphone in live mode). A safety timeout keeps this from ever
      // hanging if a platform never fires the completion callback.
      await _waitUntilSpeakingStops();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'الصوت غير متاح لهذه اللغة على جهازك.';
          _speaking = false;
        });
      }
    }
  }

  Future<void> _waitUntilSpeakingStops() async {
    // Give the start handler a brief moment to fire and flip `_speaking`
    // to true before we start checking for it to flip back to false.
    await Future.delayed(const Duration(milliseconds: 150));

    const step = Duration(milliseconds: 150);
    const maxWait = Duration(seconds: 20);
    var waited = Duration.zero;

    while (_speaking && waited < maxWait) {
      await Future.delayed(step);
      waited += step;
    }
  }

  Future<void> _speak() async {
    if (_output.trim().isEmpty) return;
    await _speakText(_output);
  }

  Future<void> _stopTts() async {
    try {
      await _tts.stop();
    } catch (_) {}

    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _shareTranslation(BuildContext shareContext) async {
    final translation = _output.trim();
    if (translation.isEmpty) return;

    final box = shareContext.findRenderObject() as RenderBox?;
    final original = _input.text.trim();
    final shareText = original.isEmpty
        ? translation
        : '$original\n\n$translation';

    try {
      await Share.share(
        shareText,
        subject: 'Voice Translator',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذرت مشاركة الترجمة من هذا الجهاز.';
        });
      }
    }
  }

  Future<void> _shareHistoryRecord(
    BuildContext shareContext,
    TranslationRecord record,
  ) async {
    final box = shareContext.findRenderObject() as RenderBox?;
    final shareText = '${record.original}\n\n${record.translated}';

    try {
      await Share.share(
        shareText,
        subject: 'Voice Translator',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذرت مشاركة الترجمة من هذا الجهاز.';
        });
      }
    }
  }

  Future<void> _copyText(String text, String message) async {
    if (text.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _swap() {
    if (_liveMode) return;

    setState(() {
      final oldFrom = _from;
      _from = _to;
      _to = oldFrom;

      final oldText = _input.text;
      _input.text = _output;
      _output = oldText;
    });

    _persistSettings();
    _loadTtsVoices();
  }

  void _clear() {
    setState(() {
      _input.clear();
      _output = '';
      _error = null;
    });
  }

  Future<void> _deleteHistoryRecord(TranslationRecord record) async {
    setState(() => _history.remove(record));
    await _saveHistory();
  }

  Future<void> _toggleFavorite(TranslationRecord record) async {
    final index = _history.indexOf(record);
    if (index < 0) return;

    setState(() {
      _history[index] = record.copyWith(
        isFavorite: !record.isFavorite,
      );
    });

    await _saveHistory();
  }

  Future<void> _clearAllHistory() async {
    if (_history.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح سجل الترجمات بالكامل؟'),
        content: const Text(
          'سيتم حذف السجل المحفوظ على الجهاز ولا يمكن التراجع عن ذلك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('مسح الكل'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _history.clear());
    await _saveHistory();
  }

  void _restoreHistory(TranslationRecord record) {
    setState(() {
      _input.text = record.original;
      _output = record.translated;
      _from = _findLanguage(record.from, _from);
      _to = _findLanguage(record.to, _to);
      _error = null;
    });

    _persistSettings();
    _loadTtsVoices();
  }

  Language _findLanguage(String name, Language fallback) {
    return languages.firstWhere(
      (language) => language.name == name,
      orElse: () => fallback,
    );
  }

  List<TranslationRecord> get _visibleHistory {
    final query = _historyQuery.toLowerCase();

    return _history.where((record) {
      if (_favoritesOnly && !record.isFavorite) return false;
      if (query.isEmpty) return true;

      return record.original.toLowerCase().contains(query) ||
          record.translated.toLowerCase().contains(query) ||
          record.from.toLowerCase().contains(query) ||
          record.to.toLowerCase().contains(query);
    }).toList();
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$dd/$mo/${local.year} • $hh:$mm';
  }

  void _showHistory() {
    _historySearch.clear();
    _favoritesOnly = false;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final records = _visibleHistory;

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * .85,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'سجل الترجمات',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: 'عرض المفضلة فقط',
                            onPressed: () {
                              setSheetState(
                                () => _favoritesOnly = !_favoritesOnly,
                              );
                            },
                            icon: Icon(
                              _favoritesOnly
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                            ),
                          ),
                          IconButton(
                            tooltip: 'مسح السجل',
                            onPressed: _history.isEmpty
                                ? null
                                : () async {
                                    await _clearAllHistory();
                                    if (sheetContext.mounted) {
                                      setSheetState(() {});
                                    }
                                  },
                            icon: const Icon(
                              Icons.delete_sweep_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        controller: _historySearch,
                        decoration: InputDecoration(
                          hintText: 'ابحث في الترجمات...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _historyQuery.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: _historySearch.clear,
                                  icon: const Icon(Icons.clear_rounded),
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: records.isEmpty
                          ? Center(
                              child: Text(
                                _history.isEmpty
                                    ? 'لا توجد ترجمات محفوظة بعد.'
                                    : 'لا توجد نتائج مطابقة.',
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                20,
                              ),
                              itemCount: records.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final record = records[index];

                                return Card(
                                  elevation: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: ListTile(
                                      onTap: () {
                                        _restoreHistory(record);
                                        Navigator.of(sheetContext).pop();
                                      },
                                      title: Text(
                                        record.original,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 6),
                                        child: Text(
                                          '${record.from} ← ${record.to}\n'
                                          '${record.translated}\n'
                                          '${_formatTime(record.time)}',
                                          maxLines: 5,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      leading: IconButton(
                                        tooltip: record.isFavorite
                                            ? 'إزالة من المفضلة'
                                            : 'إضافة إلى المفضلة',
                                        onPressed: () async {
                                          await _toggleFavorite(record);
                                          setSheetState(() {});
                                        },
                                        icon: Icon(
                                          record.isFavorite
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                        ),
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (action) async {
                                          if (action == 'copyOriginal') {
                                            await _copyText(
                                              record.original,
                                              'تم نسخ النص الأصلي',
                                            );
                                          } else if (action == 'copyTranslation') {
                                            await _copyText(
                                              record.translated,
                                              'تم نسخ الترجمة',
                                            );
                                          } else if (action == 'share') {
                                            await _shareHistoryRecord(
                                              sheetContext,
                                              record,
                                            );
                                          } else if (action == 'delete') {
                                            await _deleteHistoryRecord(
                                              record,
                                            );
                                            setSheetState(() {});
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'copyOriginal',
                                            child: Text('نسخ النص الأصلي'),
                                          ),
                                          PopupMenuItem(
                                            value: 'copyTranslation',
                                            child: Text('نسخ الترجمة'),
                                          ),
                                          PopupMenuItem(
                                            value: 'share',
                                            child: Text('مشاركة'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('حذف'),
                                          ),
                                        ],
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
            );
          },
        );
      },
    );
  }

  Future<void> _openSettings() async {
    await _loadTtsVoices();
    double draftRate = _speechRate;
    Duration draftPause = _livePause;
    bool draftAutoSpeak = _autoSpeak;
    bool draftLiveSpeak = _liveSpeak;
    Map<String, String>? draftVoice = _selectedTtsVoice;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      'الإعدادات',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: draftAutoSpeak,
                      onChanged: (value) {
                        setSheetState(() => draftAutoSpeak = value);
                      },
                      title: const Text('نطق الترجمة تلقائيًا'),
                      subtitle: const Text(
                        'عند استخدام زر الترجمة العادية',
                      ),
                    ),
                    SwitchListTile(
                      value: draftLiveSpeak,
                      onChanged: (value) {
                        setSheetState(() => draftLiveSpeak = value);
                      },
                      title: const Text('نطق الترجمة الفورية'),
                      subtitle: const Text(
                        'يتوقف الميكروفون أثناء نطق الترجمة',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'صوت التحدث: ${draftVoice?['name'] ?? 'الصوت الافتراضي'}',
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: 'تحديث الأصوات',
                          onPressed: _loadingVoices
                              ? null
                              : () async {
                                  await _loadTtsVoices();
                                  if (sheetContext.mounted) setSheetState(() {});
                                },
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    if (_voicesForTargetLanguage.isEmpty)
                      Text(
                        'لم يتم العثور على قائمة أصوات من الجهاز/المتصفح. سيتم استخدام الصوت الافتراضي.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: draftVoice == null
                            ? '__default__'
                            : '${draftVoice!['name']}|${draftVoice!['locale']}',
                        decoration: const InputDecoration(
                          labelText: 'اختر الصوت',
                          prefixIcon: Icon(Icons.record_voice_over_rounded),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '__default__',
                            child: Text('الصوت الافتراضي'),
                          ),
                          ..._voicesForTargetLanguage.map((voice) {
                            final value = '${voice['name']}|${voice['locale']}';
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                '${voice['name']} — ${voice['locale']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setSheetState(() {
                            if (value == null || value == '__default__') {
                              draftVoice = null;
                            } else {
                              draftVoice = _voicesForTargetLanguage
                                  .firstWhere((v) => '${v['name']}|${v['locale']}' == value);
                            }
                          });
                        },
                      ),
                    if (draftVoice != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => _previewTtsVoice(draftVoice!),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('تجربة الصوت'),
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'صوتك الشخصي (Voice Clone): يمكن إضافته لاحقًا عبر خدمة متخصصة لنسخ الصوت. الصوت الحالي يستخدم أصوات النظام أو المتصفح.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سرعة النطق: ${draftRate.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      min: 0.20,
                      max: 0.80,
                      divisions: 12,
                      value: draftRate,
                      label: draftRate.toStringAsFixed(2),
                      onChanged: (value) {
                        setSheetState(() => draftRate = value);
                      },
                    ),
                    const Divider(height: 28),
                    Text(
                      'زمن التوقف في الترجمة الفورية: '
                      '${draftPause.inMilliseconds} مللي ثانية',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      min: 600,
                      max: 2000,
                      divisions: 14,
                      value: draftPause.inMilliseconds.toDouble(),
                      label: '${draftPause.inMilliseconds} ms',
                      onChanged: (value) {
                        setSheetState(
                          () => draftPause =
                              Duration(milliseconds: value.round()),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'زمن أقصر يجعل الجمل تبدأ أسرع، وزمن أطول يقلل '
                      'تقطيع الجملة أثناء الترجمة الفورية.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () async {
                        setState(() {
                          _autoSpeak = draftAutoSpeak;
                          _liveSpeak = draftLiveSpeak;
                          _speechRate = draftRate;
                          _livePause = draftPause;
                          _selectedTtsVoice = draftVoice;
                        });

                        await _tts.setSpeechRate(_speechRate);
                        await _applySelectedTtsVoice();
                        await _persistSettings();

                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('حفظ الإعدادات'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Voice Translator'),
        content: const Text(
          'تطبيق ترجمة صوتية ونصية متعدد اللغات.\n\n'
          'المميزات الحالية:\n'
          '• ترجمة نصية وصوتية\n'
          '• ترجمة فورية بالصوت\n'
          '• سجل دائم على الجهاز\n'
          '• مفضلة وبحث داخل السجل\n'
          '• نسخ النص والترجمة\n'
          '• تبديل اللغات\n'
          '• وضع فاتح وداكن\n'
          '• التحكم في سرعة النطق وزمن التوقف\n\n'
          '• مشاركة الترجمة مع التطبيقات الأخرى\n'
          'الترجمة تحتاج اتصالًا بالإنترنت، ودعم الميكروفون والنطق '
          'يعتمد على الجهاز واللغة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _liveRestartTimer?.cancel();
    _liveSessionId++;
    _speech.stop();
    _tts.stop();
    _input.dispose();
    _historySearch.dispose();
    super.dispose();
  }

  BoxDecoration _neonDecoration({
    required BuildContext context,
    double radius = 22,
    bool strong = false,
    bool tinted = false,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final neon = const Color(0xFF39FF14);
    final base = dark
        ? (tinted ? const Color(0xFF0B1D0B) : const Color(0xFF0A160A))
        : (tinted ? const Color(0xFFF2FFF0) : Colors.white);
    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: dark
            ? neon.withValues(alpha: strong ? 0.42 : 0.14)
            : const Color(0xFFD8E8D4),
        width: strong ? 1.2 : 1,
      ),
      boxShadow: [
        if (dark)
          BoxShadow(
            color: neon.withValues(alpha: strong ? 0.16 : 0.055),
            blurRadius: strong ? 24 : 16,
            spreadRadius: strong ? 1 : 0,
          ),
        if (!dark)
          const BoxShadow(
            color: Color(0x16000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
      ],
    );
  }

  Widget _neonBadge({required IconData icon, required String text}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0D2B0D) : const Color(0xFFE5F8E2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark
              ? const Color(0xFF39FF14).withValues(alpha: 0.28)
              : const Color(0xFF9CD68F),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF39FF14)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: dark ? const Color(0xFFD5FFD0) : const Color(0xFF226A19),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtlInput = _from.code == 'ar' ||
        _from.code == 'fa' ||
        _from.code == 'ur';
    final isRtlOutput =
        _to.code == 'ar' || _to.code == 'fa' || _to.code == 'ur';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Voice Translator',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'المزيد',
            onSelected: (value) {
              if (value == 'themeSystem') {
                widget.onThemeChanged(ThemeMode.system);
              } else if (value == 'themeLight') {
                widget.onThemeChanged(ThemeMode.light);
              } else if (value == 'themeDark') {
                widget.onThemeChanged(ThemeMode.dark);
              } else if (value == 'about') {
                _showAbout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'themeSystem',
                child: Text('المظهر: حسب الجهاز'),
              ),
              PopupMenuItem(
                value: 'themeLight',
                child: Text('المظهر: فاتح'),
              ),
              PopupMenuItem(
                value: 'themeDark',
                child: Text('المظهر: داكن'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'about',
                child: Text('حول التطبيق'),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: theme.brightness == Brightness.dark
                      ? const [Color(0xFF102B10), Color(0xFF071407)]
                      : const [Color(0xFFEBFFE6), Color(0xFFD7FFD0)],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.42),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF39FF14).withValues(alpha: theme.brightness == Brightness.dark ? 0.15 : 0.11),
                    blurRadius: 28,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    top: -24,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF39FF14).withValues(alpha: 0.08),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF39FF14).withValues(alpha: 0.16),
                            blurRadius: 35,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF39FF14),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF39FF14).withValues(alpha: 0.42),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.graphic_eq_rounded, color: Colors.black, size: 28),
                          ),
                          const Spacer(),
                          _neonBadge(
                            icon: _liveMode ? Icons.bolt_rounded : Icons.auto_awesome_rounded,
                            text: _liveMode ? 'LIVE' : 'AI TRANSLATE',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'تحدث بلغتك. افهم العالم.',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'ترجمة نصية وصوتية بواجهة سريعة بطابع Neon حديث.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: _neonDecoration(context: context, radius: 22, tinted: true),
              child: Row(
                children: [
                    Expanded(
                      child: _languagePicker(
                        'من',
                        _from,
                        (value) {
                          setState(() => _from = value);
                          _persistSettings();
                        },
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: _liveMode ? null : _swap,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      tooltip: 'تبديل اللغتين',
                    ),
                    Expanded(
                      child: _languagePicker(
                        'إلى',
                        _to,
                        (value) {
                          setState(() => _to = value);
                          _persistSettings();
                          _loadTtsVoices();
                        },
                      ),
                    ),
                  ],
                ),
            ),
            const SizedBox(height: 12),
            _panel(
              title: 'الكلام الأصلي',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_input.text.isNotEmpty)
                    IconButton(
                      onPressed: () => _copyText(
                        _input.text,
                        'تم نسخ النص الأصلي',
                      ),
                      icon: const Icon(Icons.copy_rounded),
                      tooltip: 'نسخ',
                    ),
                  IconButton(
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'مسح',
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _input,
                    minLines: 4,
                    maxLines: 8,
                    textDirection:
                        isRtlInput ? TextDirection.rtl : TextDirection.ltr,
                    decoration: const InputDecoration(
                      hintText: 'اكتب هنا أو اضغط على الميكروفون...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _translate(),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _liveMode ? null : _listen,
                          icon: Icon(
                            _listening && !_liveMode
                                ? Icons.stop_circle_outlined
                                : Icons.mic_none_rounded,
                          ),
                          label: Text(
                            _listening && !_liveMode
                                ? 'إيقاف الاستماع'
                                : 'تحدث',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _translate,
                          icon: _busy
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.translate_rounded),
                          label: Text(
                            _busy ? 'جارٍ الترجمة' : 'ترجم',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: (_liveMode && !_liveProcessing && !_listening)
                          ? [
                              BoxShadow(
                                color: const Color(0xFF39FF14).withValues(alpha: 0.65),
                                blurRadius: 24,
                                spreadRadius: 1,
                              ),
                            ]
                          : const [],
                    ),
                    child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _liveMode
                            ? const Color(0xFF2A1111)
                            : const Color(0xFF143A15),
                        foregroundColor: _liveMode
                            ? const Color(0xFFFF8A80)
                            : const Color(0xFFB8FF9A),
                        side: BorderSide(
                          color: _liveMode
                              ? const Color(0xFFFF6B63).withValues(alpha: 0.55)
                              : const Color(0xFF39FF14).withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _toggleLiveTranslation,
                      icon: Icon(
                        _liveMode
                            ? Icons.stop_circle_outlined
                            : Icons.record_voice_over_rounded,
                      ),
                      label: Text(
                        _liveMode
                            ? 'إيقاف الترجمة الصوتية الفورية'
                            : 'تشغيل الترجمة الصوتية الفورية',
                      ),
                    ),
                    ),
                  ),
                  if (_liveMode) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF0B210B)
                            : const Color(0xFFE9FBE7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF39FF14).withValues(alpha: 0.26),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _liveProcessing || _listening
                                  ? const Color(0xFF39FF14)
                                  : theme.colorScheme.outline,
                              boxShadow: [
                                if (_liveProcessing || _listening)
                                  BoxShadow(
                                    color: const Color(0xFF39FF14).withValues(alpha: 0.55),
                                    blurRadius: 10,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _liveProcessing
                                  ? 'جارٍ ترجمة الجملة...'
                                  : _listening
                                      ? 'استمع الآن...'
                                      : 'جاهز للجملة التالية',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Icon(
                            _listening ? Icons.mic_rounded : Icons.mic_off_rounded,
                            size: 18,
                            color: _listening ? const Color(0xFF39FF14) : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _panel(
              title: 'الترجمة',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_speaking)
                    IconButton(
                      onPressed: _stopTts,
                      icon: const Icon(Icons.stop_circle_outlined),
                      tooltip: 'إيقاف الصوت',
                    ),
                  IconButton(
                    onPressed: _speak,
                    icon: const Icon(Icons.volume_up_rounded),
                    tooltip: 'استمع',
                  ),
                  Builder(
                    builder: (shareContext) {
                      return IconButton(
                        onPressed: () => _shareTranslation(shareContext),
                        icon: const Icon(Icons.share_rounded),
                        tooltip: 'مشاركة الترجمة',
                      );
                    },
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    _output.isEmpty
                        ? 'ستظهر الترجمة هنا...'
                        : _output,
                    textDirection: isRtlOutput
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      height: 1.7,
                      color: _output.isEmpty
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  if (_output.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: () => _copyText(
                              _output,
                              'تم نسخ الترجمة',
                            ),
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('نسخ'),
                          ),
                          TextButton.icon(
                            onPressed: _speak,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('استمع'),
                          ),
                          Builder(
                            builder: (shareContext) {
                              return TextButton.icon(
                                onPressed: () => _shareTranslation(shareContext),
                                icon: const Icon(Icons.share_rounded),
                                label: const Text('مشاركة'),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _error = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'سجل الترجمات',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _history.isEmpty ? null : _showHistory,
                  icon: const Icon(Icons.history_rounded),
                  label: Text('${_history.length}'),
                ),
              ],
            ),
            if (_history.isEmpty)
              Text(
                'ستظهر الترجمات التي تنفذها هنا.',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('الإعدادات'),
                  onPressed: _openSettings,
                ),
                ActionChip(
                  avatar: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('السجل'),
                  onPressed: _history.isEmpty ? null : _showHistory,
                ),
                ActionChip(
                  avatar: const Icon(Icons.stop_circle_outlined, size: 18),
                  label: const Text('إيقاف الصوت'),
                  onPressed: _speaking ? _stopTts : null,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'الترجمة تحتاج إلى الإنترنت. دعم الميكروفون والنطق يختلف حسب الجهاز واللغة. الإعدادات والسجل محفوظان على جهازك.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languagePicker(
    String label,
    Language selected,
    ValueChanged<Language> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        DropdownButton<Language>(
          value: selected,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          items: languages
              .map(
                (language) => DropdownMenuItem(
                  value: language,
                  child: Text(
                    language.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }

  Widget _panel({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Container(
      decoration: _neonDecoration(
        context: context,
        radius: 22,
        strong: title == 'الترجمة',
        tinted: title == 'الترجمة',
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 21,
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF39FF14).withValues(alpha: dark ? 0.5 : 0.16),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class TranslationRecord {
  final String original;
  final String translated;
  final String from;
  final String to;
  final DateTime time;
  final bool isFavorite;

  const TranslationRecord(
    this.original,
    this.translated,
    this.from,
    this.to,
    this.time,
    this.isFavorite,
  );

  TranslationRecord copyWith({
    String? original,
    String? translated,
    String? from,
    String? to,
    DateTime? time,
    bool? isFavorite,
  }) {
    return TranslationRecord(
      original ?? this.original,
      translated ?? this.translated,
      from ?? this.from,
      to ?? this.to,
      time ?? this.time,
      isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original': original,
      'translated': translated,
      'from': from,
      'to': to,
      'time': time.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory TranslationRecord.fromJson(Map<String, dynamic> json) {
    return TranslationRecord(
      json['original'] as String? ?? '',
      json['translated'] as String? ?? '',
      json['from'] as String? ?? '',
      json['to'] as String? ?? '',
      DateTime.tryParse(
            json['time'] as String? ?? '',
          ) ??
          DateTime.now(),
      json['isFavorite'] as bool? ?? false,
    );
  }
}
