import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'notification_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'heron_api_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.initialize();

  runApp(const HerONApp());
}
// ==================== THEME ====================

const Color bgTop = Color(0xFF290536);
const Color bgBottom = Color(0xFF050D32);
const Color cardColor = Color(0xFF211744);
const Color violet = Color(0xFF8650F5);
const Color magenta = Color(0xFFC022D5);
const Color softWhite = Color(0xFFF6F1FF);
const Color mutedText = Color(0xFFB7ACD6);

const LinearGradient appGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [bgTop, bgBottom],
);

class HerONApp extends StatelessWidget {
  const HerONApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HerON',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgBottom,
        colorScheme: ColorScheme.fromSeed(
          seedColor: violet,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}

// ==================== COMMON WIDGETS ====================

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: appGradient),
      child: SafeArea(child: child),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [violet, magenta],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

// ==================== CALCULATOR DISGUISE ====================

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String display = '0';
  double? firstNumber;
  String? operator;
  bool startNewNumber = false;

  final String secretPin = '2580';

  void press(String value) {
    setState(() {
      if (value == 'AC') {
        display = '0';
        firstNumber = null;
        operator = null;
        startNewNumber = false;
        return;
      }

      if (value == '⌫') {
        if (display.length > 1) {
          display = display.substring(0, display.length - 1);
        } else {
          display = '0';
        }
        return;
      }

      if (['+', '−', '×', '÷'].contains(value)) {
        firstNumber = double.tryParse(display);
        operator = value;
        startNewNumber = true;
        return;
      }

      if (value == '.') {
        if (startNewNumber) {
          display = '0.';
          startNewNumber = false;
        } else if (!display.contains('.')) {
          display += '.';
        }
        return;
      }

      if (value == '=') {
        // Secret PIN: enter 2580 and press equals.
        if (display == secretPin &&
            firstNumber == null &&
            operator == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const HerONHomeScreen(),
              ),
            );
          });
          return;
        }

        if (firstNumber != null && operator != null) {
          final secondNumber = double.tryParse(display) ?? 0;
          double result = 0;

          switch (operator) {
            case '+':
              result = firstNumber! + secondNumber;
              break;
            case '−':
              result = firstNumber! - secondNumber;
              break;
            case '×':
              result = firstNumber! * secondNumber;
              break;
            case '÷':
              if (secondNumber == 0) {
                display = 'Error';
                firstNumber = null;
                operator = null;
                return;
              }
              result = firstNumber! / secondNumber;
              break;
          }

          display = result == result.truncateToDouble()
              ? result.toInt().toString()
              : result.toStringAsPrecision(8);

          firstNumber = null;
          operator = null;
          startNewNumber = true;
        }
        return;
      }

      if (startNewNumber || display == '0' || display == 'Error') {
        display = value;
        startNewNumber = false;
      } else if (display.length < 12) {
        display += value;
      }
    });
  }

  Widget calculatorButton(
    String label, {
    Color? color,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: color ?? const Color(0xFF251A49),
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () => press(label),
            child: SizedBox(
              height: 67,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: label == 'AC' ? magenta : softWhite,
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.calculate_outlined,
                  color: Colors.white70,
                  size: 25,
                ),
              ),

              const Spacer(),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: const Color(0xFFBFB3EC),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    display,
                    style: const TextStyle(
                      color: Color(0xFF19102F),
                      fontSize: 38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              for (final row in [
                ['AC', '⌫', '÷', '×'],
                ['7', '8', '9', '−'],
                ['4', '5', '6', '+'],
                ['1', '2', '3', '='],
              ])
                Row(
                  children: [
                    for (final key in row)
                      calculatorButton(
                        key,
                        color: ['÷', '×', '−', '+', '='].contains(key)
                            ? const Color(0xFF622C88)
                            : null,
                      ),
                  ],
                ),

              Row(
                children: [
                  calculatorButton('0', flex: 2),
                  calculatorButton('.'),
                  calculatorButton(
                    '=',
                    color: const Color(0xFF622C88),
                  ),
                ],
              ),

              const Spacer(),

              const Text(
                'Calculator',
                style: TextStyle(color: mutedText, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HERON HOME ====================

class HerONHomeScreen extends StatefulWidget {
  const HerONHomeScreen({super.key});

  @override
  State<HerONHomeScreen> createState() => _HerONHomeScreenState();
}

class _HerONHomeScreenState extends State<HerONHomeScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: violet, size: 27),
                  const SizedBox(width: 9),
                  const Text(
                    'HerON',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_circle_outlined, size: 28),
                    tooltip: 'Profile and settings',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const CalculatorScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.lock_outline),
                    tooltip: 'Return to calculator',
                  ),
                ],
              ),
            ),

            Expanded(
              child: IndexedStack(
                index: selectedTab,
                children: const [
                  TravelScreen(),
                  EvidenceScreen(),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(15, 8, 15, 12),
              decoration: BoxDecoration(
                color: bgBottom.withValues(alpha: 0.85),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  navItem(Icons.location_on_outlined, 'Travel', 0),
                  navItem(Icons.folder_outlined, 'Evidence', 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String label, int index) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [violet, magenta])
                : null,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? Colors.white : mutedText),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== TRAVEL TAB ====================

class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  bool journeyActive = false;
  bool checkInPending = false;

  int intervalMinutes = 5;
  int responseSeconds = 30;

  Timer? checkInTimer;
  Timer? responseTimer;

  String status = 'Ready';
  final List<String> activity = [];

  @override
  void dispose() {
    checkInTimer?.cancel();
    responseTimer?.cancel();
    super.dispose();
  }

  void addActivity(String message) {
    setState(() {
      activity.insert(
        0,
        '${TimeOfDay.now().format(context)} • $message',
      );
    });
  }

  Future<void> startJourney() async {
    checkInTimer?.cancel();
    responseTimer?.cancel();

    setState(() {
      journeyActive = true;
      checkInPending = false;
      status = 'Journey Active';
    });

    addActivity('Journey started');

    await NotificationService.instance.scheduleCheckInNotification(
      delay: Duration(minutes: intervalMinutes),
    );

    scheduleCheckIn();
  }
  void scheduleCheckIn() {
    checkInTimer?.cancel();

    if (!journeyActive) return;

    checkInTimer = Timer(
      Duration(minutes: intervalMinutes),
      askForCheckIn,
    );
  }

  void askForCheckIn() {
    if (!mounted || !journeyActive) return;

    setState(() {
      checkInPending = true;
      status = 'Awaiting Check-in';
    });

    addActivity('Check-in requested');

    // Prototype only: this timer works while the app process is active.
    responseTimer = Timer(
      Duration(seconds: responseSeconds),
      () {
        if (!mounted || !journeyActive || !checkInPending) return;

        setState(() {
          checkInPending = false;
          status = 'Missed Check-in';
        });

        addActivity('MISSED CHECK-IN — alert integration pending');
      },
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'ARE YOU OK?',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Your check-in is due. Please confirm your safety.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                confirmSafe();
              },
              child: const Text("I'm OK"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                reportUnsafe();
              },
              child: const Text(
                'I feel unsafe',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> confirmSafe() async {
    responseTimer?.cancel();

    setState(() {
      checkInPending = false;
      status = 'Journey Active';
    });

    addActivity('User confirmed safety');

    await NotificationService.instance.cancelScheduledCheckIn();

    await NotificationService.instance.scheduleCheckInNotification(
      delay: Duration(minutes: intervalMinutes),
    );

    scheduleCheckIn();
  }

  Future<void> reportUnsafe() async {
    checkInTimer?.cancel();
    responseTimer?.cancel();
    await NotificationService.instance.cancelScheduledCheckIn();

    if (!mounted) return;

    setState(() {
      checkInPending = false;
      status = 'Sending SOS...';
    });
    addActivity('SOS requested');

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawContacts = prefs.getString('heron_trusted_contacts');
      final List<String> chatIds = [];

      if (rawContacts != null) {
        final decoded = jsonDecode(rawContacts) as List<dynamic>;
        for (final item in decoded) {
          final contact = Map<String, dynamic>.from(item as Map);
          final chatId = (contact['chatId'] ?? '').toString().trim();
          if (chatId.isNotEmpty) chatIds.add(chatId);
        }
      }

      if (chatIds.isEmpty) {
        if (!mounted) return;
        setState(() => status = 'SOS Not Sent');
        addActivity('SOS failed — add Telegram Chat ID to a trusted contact');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No Telegram Chat IDs saved. Add a contact Chat ID in Profile & Settings first.'),
          ),
        );
        return;
      }

      await HeronApiService.sendEmergencyAlert(
        reason: 'I feel unsafe. Please contact me and check my safety.',
        trustedContactChatIds: chatIds,
      );

      if (!mounted) return;
      setState(() => status = 'SOS Sent');
      addActivity('SOS alert sent to trusted contact(s) via Telegram');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS alert sent to your linked trusted contact(s).')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => status = 'SOS Failed');
      addActivity('SOS failed — check internet/backend/API settings');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SOS was not sent. Check backend connection and API settings.')),
      );
    }
  }

  Future<void> endJourney() async {
    checkInTimer?.cancel();
    responseTimer?.cancel();

    await NotificationService.instance.cancelScheduledCheckIn();

    if (!mounted) return;

    setState(() {
      journeyActive = false;
      checkInPending = false;
      status = 'Ready';
    });

    addActivity('Journey ended');
  }
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
      children: [
        GlassCard(
          child: Column(
            children: [
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF120B36),
                  border: Border.all(
                    color: journeyActive ? magenta : violet,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: violet.withValues(alpha: 0.15),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      journeyActive
                          ? Icons.directions_walk
                          : Icons.shield_outlined,
                      size: 28,
                      color: violet,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Journey status',
                      style: TextStyle(color: mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              if (!journeyActive)
                GradientButton(
                  text: 'Start Journey',
                  icon: Icons.play_arrow_rounded,
                  onPressed: startJourney,
                )
              else
                Column(
                  children: [
                    if (checkInPending)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: confirmSafe,
                          child: const Text("I'm OK"),
                        ),
                      ),
                    GradientButton(
                      text: 'End Journey',
                      icon: Icons.stop_circle_outlined,
                      onPressed: endJourney,
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: () async {
            await NotificationService.instance.showCheckInNotification();
          },
          icon: const Icon(Icons.notifications_active),
          label: const Text('Test Notification'),
        ),
        
        const SizedBox(height: 16),

        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Check-in settings',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Ask me every',
                style: TextStyle(color: mutedText),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<int>(
                initialValue: intervalMinutes,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF100B30),
                  border: OutlineInputBorder(),
                ),
                items: [1, 2, 5, 10, 15, 30].map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text('$minutes minute${minutes == 1 ? '' : 's'}'),
                  );
                }).toList(),
                onChanged: journeyActive
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => intervalMinutes = value);
                        }
                      },
              ),

              const SizedBox(height: 16),

              const Text(
                'Time to answer',
                style: TextStyle(color: mutedText),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<int>(
                initialValue: responseSeconds,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF100B30),
                  border: OutlineInputBorder(),
                ),
                items: [15, 30, 45, 60].map((seconds) {
                  return DropdownMenuItem(
                    value: seconds,
                    child: Text('$seconds seconds'),
                  );
                }).toList(),
                onChanged: journeyActive
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => responseSeconds = value);
                        }
                      },
              ),

              const SizedBox(height: 12),

              const Text(
                'Prototype: keep the app open during the journey. '
                'Background notifications are not implemented yet.',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activity',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (activity.isEmpty)
                const Text(
                  'Nothing yet.',
                  style: TextStyle(color: mutedText),
                )
              else
                ...activity.take(8).map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 7,
                          color: violet,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            event,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== EVIDENCE TAB ====================

class EvidenceScreen extends StatefulWidget {
  const EvidenceScreen({super.key});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class EvidenceItem {
  final File image;
  final String category;
  final String summary;
  final String advice;
  final DateTime time;

  EvidenceItem({
    required this.image,
    required this.category,
    required this.summary,
    required this.advice,
    required this.time,
  });
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final ImagePicker picker = ImagePicker();

  File? selectedImage;
  bool analyzing = false;
  String note = '';

  final List<EvidenceItem> evidence = [];

  Future<void> chooseImage() async {
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked == null) return;

      setState(() {
        selectedImage = File(picked.path);
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to select image: $error')),
      );
    }
  }

  // Demonstration only. This does not use an AI model.
  EvidenceItem demoAnalysis(File image) {
    final text = note.toLowerCase();

    String category = 'Needs review';
    String summary =
        'The screenshot has been saved for review. '
        'No automated image understanding has been performed.';
    String advice =
        'Review the original conversation, preserve the evidence, '
        'and choose a suitable next step.';

    if (text.contains('blackmail') ||
        text.contains('sextortion') ||
        text.contains('private photos')) {
      category = 'Possible sextortion';
      summary =
          'Your note mentions possible blackmail or threats involving '
          'private images. The screenshot itself has not been analyzed.';
      advice =
          'Preserve the original messages. Avoid sending money or '
          'additional private material. Consider reporting the account '
          'and contacting someone you trust.';
    } else if (text.contains('follow') ||
        text.contains('stalk') ||
        text.contains('location')) {
      category = 'Possible stalking';
      summary =
          'Your note mentions following or location-related concerns. '
          'This is a preliminary label based on your note only.';
      advice =
          'Save relevant messages and dates. Review location sharing '
          'and seek help if you feel unsafe.';
    } else if (text.contains('threat') ||
        text.contains('kill') ||
        text.contains('hurt')) {
      category = 'Possible threat';
      summary =
          'Your note mentions threatening language. '
          'The image content has not been verified.';
      advice =
          'Preserve the original evidence. If there is immediate danger, '
          'move to a safer place and contact local emergency services.';
    } else if (text.contains('message') ||
        text.contains('harass') ||
        text.contains('abuse')) {
      category = 'Possible harassment';
      summary =
          'Your note mentions potentially unwanted or abusive messages. '
          'This is not an AI-based assessment.';
      advice =
          'Keep the original conversation, consider blocking or '
          'reporting the account if safe, and seek support if needed.';
    }

    return EvidenceItem(
      image: image,
      category: category,
      summary: summary,
      advice: advice,
      time: DateTime.now(),
    );
  }

  Future<void> analyzeAndSave() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a screenshot first.'),
        ),
      );
      return;
    }

    setState(() => analyzing = true);

    // Simulates processing for the initial UI prototype.
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    final item = demoAnalysis(selectedImage!);

    setState(() {
      evidence.insert(0, item);
      analyzing = false;
      selectedImage = null;
      note = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Evidence saved. This is a demo classification, not real AI.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add evidence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Screenshot / photo',
                style: TextStyle(color: mutedText),
              ),
              const SizedBox(height: 12),

              if (selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    selectedImage!,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),

              OutlinedButton.icon(
                onPressed: chooseImage,
                icon: const Icon(Icons.upload_file),
                label: Text(
                  selectedImage == null
                      ? 'Choose screenshot'
                      : 'Choose another image',
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Your note (optional)',
                style: TextStyle(color: mutedText),
              ),
              const SizedBox(height: 8),

              TextField(
                onChanged: (value) => note = value,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe what happened...',
                  filled: true,
                  fillColor: const Color(0xFF100B30),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              GradientButton(
                text: analyzing ? 'Processing...' : 'Analyse & save',
                icon: Icons.shield_outlined,
                onPressed: analyzing ? () {} : analyzeAndSave,
              ),

              const SizedBox(height: 10),

              const Text(
                'Demo only: the current classifier uses your note, '
                'not the screenshot contents. Real AI will be added later.',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Evidence history',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (evidence.isEmpty)
          const GlassCard(
            child: Text(
              'No evidence saved yet.',
              style: TextStyle(color: mutedText),
            ),
          )
        else
          ...evidence.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: InkWell(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: cardColor,
                      title: Text(item.category),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.file(item.image),
                            const SizedBox(height: 12),
                            Text(item.summary),
                            const SizedBox(height: 12),
                            const Text(
                              'Suggested next step',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(item.advice),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          item.image,
                          width: 65,
                          height: 65,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: mutedText,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              TimeOfDay.fromDateTime(item.time)
                                  .format(context),
                              style: const TextStyle(
                                color: mutedText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: mutedText,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}


// ==================== PROFILE & SETTINGS ====================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  List<Map<String, String>> _contacts = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('heron_profile_name') ?? '';
    _phoneController.text = prefs.getString('heron_profile_phone') ?? '';
    _emailController.text = prefs.getString('heron_profile_email') ?? '';

    final savedContacts = prefs.getString('heron_trusted_contacts');
    if (savedContacts != null) {
      try {
        final decoded = jsonDecode(savedContacts) as List<dynamic>;
        _contacts = decoded.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return <String, String>{
            'name': (map['name'] ?? '').toString(),
            'phone': (map['phone'] ?? '').toString(),
            'chatId': (map['chatId'] ?? '').toString(),
          };
        }).toList();
      } catch (_) {
        _contacts = [];
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveDetails() async {
    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('heron_profile_name', _nameController.text.trim());
    await prefs.setString('heron_profile_phone', _phoneController.text.trim());
    await prefs.setString('heron_profile_email', _emailController.text.trim());
    await prefs.setString('heron_trusted_contacts', jsonEncode(_contacts));

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile and trusted contacts saved on this device.')),
    );
  }

  Future<void> _showContactDialog({int? index}) async {
    final isEditing = index != null;
    final nameController = TextEditingController(
      text: isEditing ? _contacts[index]['name'] ?? '' : '',
    );
    final phoneController = TextEditingController(
      text: isEditing ? _contacts[index]['phone'] ?? '' : '',
    );
    final chatIdController = TextEditingController(
      text: isEditing ? _contacts[index]['chatId'] ?? '' : '',
    );
    final dialogFormKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(isEditing ? 'Edit trusted contact' : 'Add trusted contact'),
        content: Form(
          key: dialogFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Contact name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a phone number'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: chatIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Telegram Chat ID',
                  helperText: 'Required for Telegram SOS alerts',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (dialogFormKey.currentState!.validate()) {
                Navigator.pop(dialogContext, {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'chatId': chatIdController.text.trim(),
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // The dialog route may still be finishing its exit animation when
    // showDialog returns. Dispose the controllers after that transition so
    // the dialog's TextFields are no longer listening to them.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      nameController.dispose();
      phoneController.dispose();
      chatIdController.dispose();
    });

    if (result == null || !mounted) return;
    setState(() {
      if (isEditing) {
        _contacts[index] = result;
      } else {
        _contacts.add(result);
      }
    });
    await _saveDetails();
  }

  Future<void> _deleteContact(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Delete contact?'),
        content: Text('Remove ${_contacts[index]['name']} from trusted contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _contacts.removeAt(index));
      await _saveDetails();
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: violet),
      filled: true,
      fillColor: const Color(0xFF100B30),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: bgTop,
      ),
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.person_outline, color: violet, size: 25),
                              SizedBox(width: 9),
                              Text(
                                'My Profile',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration('Full name', Icons.badge_outlined),
                            validator: (value) => value == null || value.trim().isEmpty
                                ? 'Please enter your name'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration('Phone number', Icons.phone_outlined),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration('Email (optional)', Icons.email_outlined),
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty &&
                                  !value.trim().contains('@')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_outline, color: violet, size: 25),
                              const SizedBox(width: 9),
                              const Expanded(
                                child: Text(
                                  'Trusted Contacts',
                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showContactDialog(),
                                icon: const Icon(Icons.person_add_alt_1, color: violet),
                                tooltip: 'Add trusted contact',
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Add each trusted contact’s Telegram Chat ID to enable SOS alerts. They must have started your Telegram bot first.',
                            style: TextStyle(color: mutedText, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          if (_contacts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('No trusted contacts added yet.',
                                  style: TextStyle(color: mutedText)),
                            )
                          else
                            ..._contacts.asMap().entries.map((entry) {
                              final index = entry.key;
                              final contact = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF100B30),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: violet,
                                    child: Icon(Icons.person_outline, color: Colors.white),
                                  ),
                                  title: Text(contact['name'] ?? ''),
                                  subtitle: Text(
                                    '${contact['phone'] ?? ''} • Telegram ID: ${(contact['chatId'] ?? '').isEmpty ? 'not set' : contact['chatId']}',
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showContactDialog(index: index);
                                      } else if (value == 'delete') {
                                        _deleteContact(index);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          OutlinedButton.icon(
                            onPressed: () => _showContactDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add trusted contact'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    GradientButton(
                      text: _saving ? 'Saving...' : 'Save Changes',
                      icon: Icons.save_outlined,
                      onPressed: _saving
                          ? () {}
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _saveDetails();
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Profile and contacts are saved only on this device. Telegram alerts require a valid Chat ID, a working backend, and internet access.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

