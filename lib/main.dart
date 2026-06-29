import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const TrackerApp());

const String appTitle = 'متابعة القياسات';
const String appVersion = 'V4';
const String developerEmail = 'fastunlocked2017@gmail.com';
const Color seedColor = Color(0xFF0E7490);

class Entry {
  final double value;
  final String note;
  final DateTime date;
  const Entry({required this.value, required this.note, required this.date});
  String encode() => '${value.toStringAsFixed(1)}|||$note|||${date.toIso8601String()}';
  static Entry decode(String raw) { final p = raw.split('|||'); return Entry(value: p.isNotEmpty ? double.tryParse(p[0]) ?? 0 : 0, note: p.length > 1 ? p[1] : '', date: p.length > 2 ? DateTime.tryParse(p[2]) ?? DateTime.now() : DateTime.now()); }
}

class TrackerApp extends StatelessWidget {
  const TrackerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: appTitle,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: seedColor), scaffoldBackgroundColor: const Color(0xFFECFEFF), fontFamily: 'Arial'),
    home: const Directionality(textDirection: TextDirection.rtl, child: HomeScreen()),
  );
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  bool reminders = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 0);
  final valueCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  List<Entry> entries = [];

  @override void initState() { super.initState(); load(); }
  Future<void> load() async { final p = await SharedPreferences.getInstance(); final saved = p.getStringList('measure_log_v4') ?? p.getStringList('measure_log_v3'); setState(() { entries = (saved == null || saved.isEmpty) ? [] : saved.map(Entry.decode).toList(); reminders = p.getBool('measure_reminders') ?? false; reminderTime = TimeOfDay(hour: p.getInt('measure_h') ?? 8, minute: p.getInt('measure_m') ?? 0); }); }
  Future<void> save() async { final p = await SharedPreferences.getInstance(); await p.setStringList('measure_log_v4', entries.map((e) => e.encode()).toList()); await p.setBool('measure_reminders', reminders); await p.setInt('measure_h', reminderTime.hour); await p.setInt('measure_m', reminderTime.minute); }

  double get current => entries.isEmpty ? 0 : entries.first.value;
  double get previous => entries.length < 2 ? 0 : entries[1].value;
  double get change => entries.length < 2 ? 0 : current - previous;

  void addEntry() { final v = double.tryParse(valueCtrl.text.trim().replaceAll(',', '.')); if (v == null || v <= 0) return; setState(() { entries.insert(0, Entry(value: v, note: noteCtrl.text.trim(), date: DateTime.now())); valueCtrl.clear(); noteCtrl.clear(); }); save(); SystemSound.play(SystemSoundType.click); }
  void deleteEntry(int i) { final old = entries[i]; setState(() => entries.removeAt(i)); save(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم حذف القياس'), action: SnackBarAction(label: 'تراجع', onPressed: () { setState(() => entries.insert(i, old)); save(); }))); }
  void copyLog() { Clipboard.setData(ClipboardData(text: entries.map((e) => '${date(e.date)} - ${e.value.toStringAsFixed(1)} - ${e.note}').join('\n'))); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ السجل'))); }

  @override Widget build(BuildContext context) { final pages = [dashboard(), recordPage(), historyPage(), settingsPage(), aboutPage()]; return Scaffold(body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: pages[index])), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'الرئيسية'), NavigationDestination(icon: Icon(Icons.add_chart_rounded), label: 'تسجيل'), NavigationDestination(icon: Icon(Icons.timeline_rounded), label: 'السجل'), NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'الإعدادات'), NavigationDestination(icon: Icon(Icons.info_rounded), label: 'عن')])); }

  Widget dashboard() => ListView(padding: const EdgeInsets.all(16), children: [hero(), const SizedBox(height: 14), Row(children: [Expanded(child: stat('آخر قياس', current == 0 ? '-' : current.toStringAsFixed(1), Icons.straighten_rounded)), const SizedBox(width: 10), Expanded(child: stat('آخر تغير', entries.length < 2 ? '-' : change.toStringAsFixed(1), Icons.compare_arrows_rounded))]), const SizedBox(height: 14), infoCard(), const SizedBox(height: 14), section('تسجيل سريع'), entryCard(compact: true), const SizedBox(height: 14), section('آخر القياسات'), if (entries.isEmpty) empty(), ...entries.take(3).map((e) => entryTile(entries.indexOf(e)))]);
  Widget recordPage() => ListView(padding: const EdgeInsets.all(16), children: [pageHeader('تسجيل قياس', 'اكتب الرقم مع ملاحظة اختيارية، بدون أحكام أو ضغط.'), entryCard(compact: false)]);
  Widget historyPage() => ListView(padding: const EdgeInsets.all(16), children: [pageHeader('السجل', 'احتفظ بسجل مرتب تستطيع نسخه متى أردت.'), FilledButton.icon(onPressed: entries.isEmpty ? null : copyLog, icon: const Icon(Icons.copy_all_rounded), label: const Text('نسخ السجل')), const SizedBox(height: 12), chartCard(), const SizedBox(height: 12), if (entries.isEmpty) empty(), ...entries.map((e) => entryTile(entries.indexOf(e)))]);
  Widget settingsPage() => ListView(padding: const EdgeInsets.all(16), children: [pageHeader('الإعدادات', 'خيارات بسيطة للتنظيم فقط.'), card(SwitchListTile(value: reminders, onChanged: (v) { setState(() => reminders = v); save(); }, title: const Text('تذكير اختياري'), subtitle: Text(reminders ? 'مفعل عند ${reminderTime.format(context)}' : 'متوقف'), secondary: const Icon(Icons.notifications_active_rounded))), const SizedBox(height: 10), card(ListTile(leading: const Icon(Icons.schedule_rounded), title: const Text('وقت التذكير'), subtitle: Text(reminderTime.format(context)), trailing: const Icon(Icons.chevron_left_rounded), onTap: () async { final t = await showTimePicker(context: context, initialTime: reminderTime); if (t != null) { setState(() => reminderTime = t); save(); } }))]);
  Widget aboutPage() => ListView(padding: const EdgeInsets.all(16), children: [pageHeader('عن التطبيق', 'أداة تنظيم شخصية ومحايدة.'), card(const Text('$appTitle V4\nتصميم أهدأ، حفظ على V4 مع قراءة V3، وسجل مرتب بدون رسائل ضغط أو أحكام.'))]);

  Widget hero() => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0E7490), Color(0xFF14B8A6)]), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: seedColor.withValues(alpha: .20), blurRadius: 28, offset: const Offset(0, 14))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('$appTitle V4', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(entries.isEmpty ? 'ابدأ بتسجيل أول قياس' : 'آخر قياس: ${current.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)), Text('${entries.length} قياس محفوظ', style: const TextStyle(color: Colors.white70))]));
  Widget entryCard({required bool compact}) => card(Column(children: [TextField(controller: valueCtrl, keyboardType: TextInputType.number, decoration: input('القياس', Icons.straighten_rounded)), if (!compact) const SizedBox(height: 8), if (!compact) TextField(controller: noteCtrl, decoration: input('ملاحظة اختيارية', Icons.notes_rounded)), const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: addEntry, icon: const Icon(Icons.save_rounded), label: const Text('حفظ')))]));
  Widget chartCard() { final latest = entries.take(7).toList().reversed.toList(); final maxV = latest.isEmpty ? 1 : latest.map((e) => e.value).reduce((a, b) => a > b ? a : b); return card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('عرض بصري بسيط', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 12), SizedBox(height: 110, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: latest.map((e) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Container(height: (e.value / maxV * 100).clamp(18, 100), decoration: BoxDecoration(color: seedColor.withValues(alpha: .72), borderRadius: BorderRadius.circular(14)))))).toList()))])); }
  Widget entryTile(int i) { final e = entries[i]; return Padding(padding: const EdgeInsets.only(bottom: 10), child: card(ListTile(leading: const CircleAvatar(child: Icon(Icons.straighten_rounded)), title: Text(e.value.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), subtitle: Text('${date(e.date)}${e.note.isEmpty ? '' : ' • ${e.note}'}'), trailing: IconButton(onPressed: () => deleteEntry(i), icon: const Icon(Icons.delete_outline_rounded))))); }
  Widget infoCard() => card(const Text('هذا التطبيق للتنظيم الشخصي فقط. لا يعتمد على مقارنة أو أحكام، ولا يغني عن رأي مختص عند الحاجة.'));
  Widget stat(String t, String v, IconData icon) => card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: seedColor), const SizedBox(height: 8), Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), Text(t)]));
  Widget pageHeader(String title, String sub) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(sub, style: TextStyle(color: Colors.grey.shade700))]));
  Widget section(String s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(s, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));
  Widget empty() => card(Center(child: Text('لا توجد قياسات بعد', style: TextStyle(color: Colors.grey.shade700))));
  InputDecoration input(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none));
  Widget card(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .045), blurRadius: 22, offset: const Offset(0, 10))]), child: child);
  String date(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}
