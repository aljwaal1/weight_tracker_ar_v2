import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const WeightApp());

const String appTitle = 'متابعة الوزن';
const String appVersion = 'V5';
const String developerEmail = 'fastunlocked2017@gmail.com';
const Color seedColor = Color(0xFF2563EB);
const Color accentColor = Color(0xFF10B981);

class WeightEntry {
  final double weight;
  final String note;
  final DateTime date;

  const WeightEntry({required this.weight, required this.note, required this.date});

  String encode() => '${weight.toStringAsFixed(1)}|||$note|||${date.toIso8601String()}';

  static WeightEntry decode(String raw) {
    final p = raw.split('|||');
    return WeightEntry(
      weight: p.isNotEmpty ? double.tryParse(p[0]) ?? 0 : 0,
      note: p.length > 1 ? p[1] : '',
      date: p.length > 2 ? DateTime.tryParse(p[2]) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class WeightApp extends StatelessWidget {
  const WeightApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: appTitle,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          fontFamily: 'Arial',
        ),
        home: const Directionality(textDirection: TextDirection.rtl, child: HomeScreen()),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  bool reminders = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 0);
  double targetWeight = 75;
  final weightCtrl = TextEditingController();
  final targetCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  List<WeightEntry> entries = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getStringList('weight_log_v5') ?? p.getStringList('measure_log_v4') ?? p.getStringList('measure_log_v3');
    setState(() {
      entries = (saved == null || saved.isEmpty) ? [] : saved.map(WeightEntry.decode).toList();
      reminders = p.getBool('weight_reminders') ?? p.getBool('measure_reminders') ?? false;
      reminderTime = TimeOfDay(hour: p.getInt('weight_h') ?? p.getInt('measure_h') ?? 8, minute: p.getInt('weight_m') ?? p.getInt('measure_m') ?? 0);
      targetWeight = p.getDouble('target_weight_v5') ?? 75;
      targetCtrl.text = targetWeight.toStringAsFixed(1);
    });
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('weight_log_v5', entries.map((e) => e.encode()).toList());
    await p.setBool('weight_reminders', reminders);
    await p.setInt('weight_h', reminderTime.hour);
    await p.setInt('weight_m', reminderTime.minute);
    await p.setDouble('target_weight_v5', targetWeight);
  }

  double get current => entries.isEmpty ? 0 : entries.first.weight;
  double get start => entries.isEmpty ? 0 : entries.last.weight;
  double get previous => entries.length < 2 ? 0 : entries[1].weight;
  double get lastChange => entries.length < 2 ? 0 : current - previous;
  double get totalChange => entries.length < 2 ? 0 : current - start;
  double get minWeight => entries.isEmpty ? 0 : entries.map((e) => e.weight).reduce(math.min);
  double get maxWeight => entries.isEmpty ? 0 : entries.map((e) => e.weight).reduce(math.max);
  double get avgWeight => entries.isEmpty ? 0 : entries.map((e) => e.weight).reduce((a, b) => a + b) / entries.length;
  double get remaining => current == 0 ? 0 : current - targetWeight;
  double get progress {
    if (entries.length < 2 || start == targetWeight) return 0;
    final total = (start - targetWeight).abs();
    final done = (start - current).abs();
    return (done / total).clamp(0, 1);
  }

  void addEntry() {
    final v = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return;
    setState(() {
      entries.insert(0, WeightEntry(weight: v, note: noteCtrl.text.trim(), date: DateTime.now()));
      weightCtrl.clear();
      noteCtrl.clear();
    });
    save();
    SystemSound.play(SystemSoundType.click);
  }

  void saveTarget() {
    final v = double.tryParse(targetCtrl.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return;
    setState(() => targetWeight = v);
    save();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ هدف الوزن')));
  }

  void deleteEntry(int i) {
    final old = entries[i];
    setState(() => entries.removeAt(i));
    save();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('تم حذف الوزن'),
      action: SnackBarAction(label: 'تراجع', onPressed: () { setState(() => entries.insert(i, old)); save(); }),
    ));
  }

  void copyLog() {
    Clipboard.setData(ClipboardData(text: entries.map((e) => '${date(e.date)} - ${e.weight.toStringAsFixed(1)} كجم - ${e.note}').join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ سجل الوزن')));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [dashboard(), recordPage(), historyPage(), settingsPage(), aboutPage()];
    return Scaffold(
      body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: pages[index])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.add_rounded), label: 'إضافة'),
          NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: 'السجل'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'الإعدادات'),
          NavigationDestination(icon: Icon(Icons.info_rounded), label: 'عن'),
        ],
      ),
    );
  }

  Widget dashboard() => ListView(padding: const EdgeInsets.all(16), children: [
        hero(),
        const SizedBox(height: 14),
        section('نظرة سريعة'),
        Row(children: [
          Expanded(child: stat('الهدف', '${targetWeight.toStringAsFixed(1)} كجم', Icons.flag_rounded)),
          const SizedBox(width: 10),
          Expanded(child: stat('المتبقي', current == 0 ? '-' : '${remaining.toStringAsFixed(1)} كجم', Icons.track_changes_rounded)),
        ]),
        const SizedBox(height: 14),
        chartCard(),
        const SizedBox(height: 14),
        section('تسجيل سريع'),
        entryCard(compact: true),
        const SizedBox(height: 14),
        section('آخر أوزان مسجلة'),
        if (entries.isEmpty) empty(),
        ...entries.take(3).map((e) => entryTile(entries.indexOf(e))),
      ]);

  Widget recordPage() => ListView(padding: const EdgeInsets.all(16), children: [
        pageHeader('إضافة وزن جديد', 'سجل وزنك فقط بالكيلوغرام، مع ملاحظة اختيارية.'),
        entryCard(compact: false),
      ]);

  Widget historyPage() => ListView(padding: const EdgeInsets.all(16), children: [
        pageHeader('سجل الوزن', 'تابع التغيرات بوضوح من دون قياسات جسم أو أطوال.'),
        FilledButton.icon(onPressed: entries.isEmpty ? null : copyLog, icon: const Icon(Icons.copy_all_rounded), label: const Text('نسخ سجل الوزن')),
        const SizedBox(height: 12),
        chartCard(),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          miniStat('أعلى وزن', maxWeight),
          miniStat('أقل وزن', minWeight),
          miniStat('المتوسط', avgWeight),
          miniStat('منذ البداية', totalChange),
        ]),
        const SizedBox(height: 12),
        if (entries.isEmpty) empty(),
        ...entries.map((e) => entryTile(entries.indexOf(e))),
      ]);

  Widget settingsPage() => ListView(padding: const EdgeInsets.all(16), children: [
        pageHeader('الإعدادات', 'هدف الوزن والتذكير الاختياري.'),
        card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('هدف الوزن', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: input('الهدف بالكجم', Icons.flag_rounded)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: saveTarget, icon: const Icon(Icons.save_rounded), label: const Text('حفظ الهدف'))),
        ])),
        const SizedBox(height: 10),
        card(SwitchListTile(
          value: reminders,
          onChanged: (v) { setState(() => reminders = v); save(); },
          title: const Text('تذكير اختياري'),
          subtitle: Text(reminders ? 'مفعل عند ${reminderTime.format(context)}' : 'متوقف'),
          secondary: const Icon(Icons.notifications_active_rounded),
        )),
        const SizedBox(height: 10),
        card(ListTile(
          leading: const Icon(Icons.schedule_rounded),
          title: const Text('وقت التذكير'),
          subtitle: Text(reminderTime.format(context)),
          trailing: const Icon(Icons.chevron_left_rounded),
          onTap: () async { final t = await showTimePicker(context: context, initialTime: reminderTime); if (t != null) { setState(() => reminderTime = t); save(); } },
        )),
      ]);

  Widget aboutPage() => ListView(padding: const EdgeInsets.all(16), children: [
        pageHeader('عن التطبيق', 'أداة بسيطة لمتابعة الوزن فقط.'),
        card(const Text('$appTitle V5\nتمت إزالة أي عناصر خاصة بقياسات الجسم أو الأطوال. التطبيق الآن مخصص لتسجيل الوزن، الهدف، الرسم البياني، والسجل الشخصي فقط.')),
      ]);

  Widget hero() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [seedColor, accentColor]),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: seedColor.withValues(alpha: .20), blurRadius: 28, offset: const Offset(0, 14))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.monitor_weight_rounded, color: Colors.white, size: 34), SizedBox(width: 8), Text('$appTitle V5', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 18),
          Text(current == 0 ? 'ابدأ بتسجيل وزنك' : '${current.toStringAsFixed(1)} كجم', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(entries.isEmpty ? 'لا توجد أوزان محفوظة بعد' : '${entries.length} وزن محفوظ • آخر تسجيل ${date(entries.first.date)}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),
          const SizedBox(height: 8),
          Text(current == 0 ? 'حدد هدفك ثم أضف أول وزن' : 'الهدف: ${targetWeight.toStringAsFixed(1)} كجم • التغير منذ البداية: ${totalChange.toStringAsFixed(1)} كجم', style: const TextStyle(color: Colors.white)),
        ]),
      );

  Widget entryCard({required bool compact}) => card(Column(children: [
        TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: input('الوزن بالكجم', Icons.monitor_weight_rounded)),
        if (!compact) const SizedBox(height: 8),
        if (!compact) TextField(controller: noteCtrl, decoration: input('ملاحظة اختيارية', Icons.notes_rounded)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: addEntry, icon: const Icon(Icons.save_rounded), label: const Text('حفظ الوزن'))),
      ]));

  Widget chartCard() {
    final latest = entries.take(10).toList().reversed.toList();
    final maxV = latest.isEmpty ? 1 : latest.map((e) => e.weight).reduce(math.max);
    final minV = latest.isEmpty ? 0 : latest.map((e) => e.weight).reduce(math.min);
    final range = (maxV - minV).abs() < .1 ? 1 : maxV - minV;
    return card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.show_chart_rounded, color: seedColor), SizedBox(width: 8), Text('منحنى الوزن', style: TextStyle(fontWeight: FontWeight.w900))]),
      const SizedBox(height: 12),
      SizedBox(
        height: 125,
        child: latest.isEmpty
            ? Center(child: Text('أضف وزنًا لعرض الرسم', style: TextStyle(color: Colors.grey.shade700)))
            : Row(crossAxisAlignment: CrossAxisAlignment.end, children: latest.map((e) {
                final h = 22 + ((e.weight - minV) / range * 88);
                return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(e.weight.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(height: h, decoration: BoxDecoration(color: seedColor.withValues(alpha: .75), borderRadius: BorderRadius.circular(14))),
                ])));
              }).toList()),
      ),
    ]));
  }

  Widget entryTile(int i) {
    final e = entries[i];
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: card(ListTile(
      leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.monitor_weight_rounded, color: seedColor)),
      title: Text('${e.weight.toStringAsFixed(1)} كجم', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      subtitle: Text('${date(e.date)}${e.note.isEmpty ? '' : ' • ${e.note}'}'),
      trailing: IconButton(onPressed: () => deleteEntry(i), icon: const Icon(Icons.delete_outline_rounded)),
    )));
  }

  Widget stat(String t, String v, IconData icon) => card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: seedColor), const SizedBox(height: 8), Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(t)]));
  Widget miniStat(String title, double value) => SizedBox(width: 155, child: card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: Colors.grey.shade700)), const SizedBox(height: 6), Text(entries.isEmpty ? '-' : '${value.toStringAsFixed(1)} كجم', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))])));
  Widget pageHeader(String title, String sub) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(sub, style: TextStyle(color: Colors.grey.shade700))]));
  Widget section(String s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(s, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));
  Widget empty() => card(Center(child: Text('لا توجد أوزان بعد', style: TextStyle(color: Colors.grey.shade700))));
  InputDecoration input(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none));
  Widget card(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .045), blurRadius: 22, offset: const Offset(0, 10))]), child: child);
  String date(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}
