import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const WeightProApp());

const String appTitle = 'متابعة الوزن';
const String appVersion = 'V2';
const String developerEmail = 'fastunlocked2017@gmail.com';
const Color seedColor = Color(0xFF0891B2);
const Color warmColor = Color(0xFFF59E0B);

class WeightEntry {
  final double weight;
  final String note;
  final DateTime date;
  const WeightEntry({required this.weight, required this.note, required this.date});
  String encode() => '${weight.toStringAsFixed(1)}|||$note|||${date.toIso8601String()}';
  static WeightEntry decode(String raw) {
    final p = raw.split('|||');
    return WeightEntry(weight: p.isNotEmpty ? double.tryParse(p[0]) ?? 75 : 75, note: p.length > 1 ? p[1] : '', date: p.length > 2 ? DateTime.tryParse(p[2]) ?? DateTime.now() : DateTime.now());
  }
}

class WeightProApp extends StatelessWidget {
  const WeightProApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: appTitle,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: seedColor), scaffoldBackgroundColor: const Color(0xFFF1FAFC), fontFamily: 'Arial'),
    home: const Directionality(textDirection: TextDirection.rtl, child: SplashScreen()),
  );
}

class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState() => _SplashScreenState(); }
class _SplashScreenState extends State<SplashScreen> {
  @override void initState() { super.initState(); Future.delayed(const Duration(milliseconds: 850), () { if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: HomeScreen()))); }); }
  @override Widget build(BuildContext context) => Scaffold(body: Container(width: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF0F766E)], begin: Alignment.topRight, end: Alignment.bottomLeft)), child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 106, height: 106, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(36), border: Border.all(color: Colors.white.withValues(alpha: .30))), child: const Text('⚖️', style: TextStyle(fontSize: 54))), const SizedBox(height: 22), const Text(appTitle, style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text('رحلة صحية بسيطة بلا تعقيد', style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 16)), const SizedBox(height: 34), const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))]))));
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  double target = 70;
  bool reminders = true;
  TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 0);
  final weightCtrl = TextEditingController();
  final targetCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  List<WeightEntry> entries = [];

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await SharedPreferences.getInstance(); final saved = p.getStringList('weights_v2'); setState(() { target = p.getDouble('target_v2') ?? 70; entries = (saved == null || saved.isEmpty) ? _starter() : saved.map(WeightEntry.decode).toList(); reminders = p.getBool('weight_reminders') ?? true; reminderTime = TimeOfDay(hour: p.getInt('weight_h') ?? 8, minute: p.getInt('weight_m') ?? 0); targetCtrl.text = target.toStringAsFixed(1); }); }
  List<WeightEntry> _starter() => [WeightEntry(weight: 75.0, note: 'بداية المتابعة', date: DateTime.now().subtract(const Duration(days: 8))), WeightEntry(weight: 74.6, note: 'تحسن بسيط', date: DateTime.now().subtract(const Duration(days: 4))), WeightEntry(weight: 74.2, note: 'استمرار جيد', date: DateTime.now())];
  Future<void> _save() async { final p = await SharedPreferences.getInstance(); await p.setStringList('weights_v2', entries.map((e) => e.encode()).toList()); await p.setDouble('target_v2', target); await p.setBool('weight_reminders', reminders); await p.setInt('weight_h', reminderTime.hour); await p.setInt('weight_m', reminderTime.minute); }
  void _sound([bool alert = false]) => SystemSound.play(alert ? SystemSoundType.alert : SystemSoundType.click);
  double get current => entries.isEmpty ? 0 : entries.first.weight;
  double get first => entries.isEmpty ? 0 : entries.last.weight;
  double get change => entries.length < 2 ? 0 : current - first;
  double get remaining => current == 0 ? 0 : (current - target).abs();
  double get progress => current == 0 ? 0 : (target / current).clamp(.05, 1.0);

  void _addEntry() { final w = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.')); if (w == null || w <= 0) return; setState(() { entries.insert(0, WeightEntry(weight: w, note: noteCtrl.text.trim(), date: DateTime.now())); weightCtrl.clear(); noteCtrl.clear(); }); _save(); _sound(); }
  void _delete(int i) { final old = entries[i]; setState(() => entries.removeAt(i)); _save(); _sound(true); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم حذف القياس'), action: SnackBarAction(label: 'تراجع', onPressed: () { setState(() => entries.insert(i, old)); _save(); }))); }
  void _updateTarget(String s) { final v = double.tryParse(s.replaceAll(',', '.')); if (v != null && v > 0) { target = v; _save(); setState(() {}); } }

  @override Widget build(BuildContext context) { final pages = [_dashboard(), _recordPage(), _historyPage(), _settingsPage(), _aboutPage()]; return Scaffold(body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: pages[index])), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) { setState(() => index = v); _sound(); }, destinations: const [NavigationDestination(icon: Icon(Icons.monitor_heart_rounded), label: 'الرئيسية'), NavigationDestination(icon: Icon(Icons.add_chart_rounded), label: 'تسجيل'), NavigationDestination(icon: Icon(Icons.timeline_rounded), label: 'السجل'), NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'الإعدادات'), NavigationDestination(icon: Icon(Icons.info_rounded), label: 'عن')])); }

  Widget _dashboard() => ListView(padding: const EdgeInsets.all(16), children: [_hero(), const SizedBox(height: 14), Row(children: [Expanded(child: _stat('الحالي', current == 0 ? '-' : '${current.toStringAsFixed(1)} كغم', Icons.scale_rounded)), const SizedBox(width: 10), Expanded(child: _stat('المتبقي', '${remaining.toStringAsFixed(1)} كغم', Icons.flag_rounded))]), const SizedBox(height: 14), _progressCard(), const SizedBox(height: 14), _sectionTitle('تسجيل سريع'), _entryCard(compact: true), const SizedBox(height: 14), _sectionTitle('آخر القياسات'), ...entries.take(3).map((e) => _entryTile(entries.indexOf(e)))]);
  Widget _recordPage() => ListView(padding: const EdgeInsets.all(16), children: [_pageHeader('تسجيل الوزن', 'سجل وزنك مع ملاحظة اختيارية لتفهم رحلتك.'), _entryCard(compact: false), const SizedBox(height: 12), ProCard(child: TextField(controller: targetCtrl, keyboardType: TextInputType.number, onChanged: _updateTarget, decoration: const InputDecoration(prefixIcon: Icon(Icons.flag_rounded), labelText: 'الهدف بالكيلو', border: InputBorder.none))), const SizedBox(height: 12), _tipCard()]);
  Widget _historyPage() => ListView(padding: const EdgeInsets.all(16), children: [_pageHeader('السجل والتحليل', 'مؤشرات مختصرة تساعدك على الاستمرار.'), Row(children: [Expanded(child: _stat('عدد القياسات', '${entries.length}', Icons.list_alt_rounded)), const SizedBox(width: 10), Expanded(child: _stat('التغير', '${change.toStringAsFixed(1)} كغم', change <= 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded))]), const SizedBox(height: 12), _chartCard(), const SizedBox(height: 12), ...entries.map((e) => _entryTile(entries.indexOf(e)))]);
  Widget _settingsPage() => ListView(padding: const EdgeInsets.all(16), children: [_pageHeader('الإعدادات', 'اجعل المتابعة مناسبة ليومك.'), ProCard(child: SwitchListTile(value: reminders, onChanged: (v) { setState(() => reminders = v); _save(); }, title: const Text('تذكير يومي للوزن'), subtitle: Text(reminders ? 'مفعل عند ${reminderTime.format(context)}' : 'متوقف'), secondary: const Icon(Icons.notifications_active_rounded))), const SizedBox(height: 10), ProCard(child: ListTile(leading: const Icon(Icons.schedule_rounded), title: const Text('وقت التذكير'), subtitle: Text(reminderTime.format(context)), trailing: const Icon(Icons.chevron_left_rounded), onTap: () async { final t = await showTimePicker(context: context, initialTime: reminderTime); if (t != null) { setState(() => reminderTime = t); _save(); } })), const SizedBox(height: 10), ProCard(child: ListTile(leading: const Icon(Icons.copy_all_rounded), title: const Text('نسخ سجل الوزن'), subtitle: const Text('للاحتفاظ بنسخة يدوية'), onTap: () { Clipboard.setData(ClipboardData(text: entries.map((e) => '${_date(e.date)} - ${e.weight.toStringAsFixed(1)} كغم - ${e.note}').join('\n'))); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ السجل'))); }))]);
  Widget _aboutPage() => ListView(padding: const EdgeInsets.all(16), children: [_pageHeader('عن التطبيق', 'متابعة صحية بدون ضغط أو تعقيد.'), ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 60, height: 60, alignment: Alignment.center, decoration: BoxDecoration(gradient: const LinearGradient(colors: [seedColor, Color(0xFF0F766E)]), borderRadius: BorderRadius.circular(20)), child: const Text('⚖️', style: TextStyle(fontSize: 30))), const SizedBox(width: 12), const Expanded(child: Text('$appTitle $appVersion', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)))]), const SizedBox(height: 12), const Text('تطبيق عربي خفيف لتسجيل الوزن، متابعة الهدف، رؤية التغير، ونسخ السجل عند الحاجة. لا يقدم نصائح طبية؛ هو أداة تنظيم شخصية فقط.') ])), const SizedBox(height: 12), ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('مراسلة المطور', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const SelectableText(developerEmail), const SizedBox(height: 12), FilledButton.icon(onPressed: () { Clipboard.setData(const ClipboardData(text: 'السلام عليكم، لدي ملاحظة حول تطبيق متابعة الوزن:\n\nالبريد: fastunlocked2017@gmail.com')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رسالة المطور'))); }, icon: const Icon(Icons.copy_all_rounded), label: const Text('نسخ الرسالة للمطور'))]))]);

  Widget _hero() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF0F766E)], begin: Alignment.topRight, end: Alignment.bottomLeft), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: seedColor.withValues(alpha: .22), blurRadius: 24, offset: const Offset(0, 12))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 64, height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(22)), child: const Text('⚖️', style: TextStyle(fontSize: 34))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text(appTitle, style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('راقب تقدمك بهدوء ووضوح', style: TextStyle(color: Colors.white.withValues(alpha: .86)))]))]), const SizedBox(height: 18), ClipRRect(borderRadius: BorderRadius.circular(18), child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: Colors.white.withValues(alpha: .22), color: Colors.white))]));
  Widget _entryCard({required bool compact}) => ProCard(child: Column(children: [TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الوزن الحالي بالكيلو', border: InputBorder.none)), if (!compact) TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'ملاحظة اختيارية', border: InputBorder.none)), Align(alignment: AlignmentDirectional.centerEnd, child: FilledButton.icon(onPressed: _addEntry, icon: const Icon(Icons.save_rounded), label: const Text('حفظ القياس')))]));
  Widget _progressCard() => ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('التقدم نحو الهدف', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)), const SizedBox(height: 8), LinearProgressIndicator(value: progress, minHeight: 10, borderRadius: BorderRadius.circular(20)), const SizedBox(height: 8), Text('الهدف: ${target.toStringAsFixed(1)} كغم', style: TextStyle(color: Colors.grey.shade700))]));
  Widget _chartCard() { final latest = entries.take(7).toList().reversed.toList(); final maxW = latest.isEmpty ? 1 : latest.map((e) => e.weight).reduce((a, b) => a > b ? a : b); return ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('رسم مبسط لآخر القياسات', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 12), SizedBox(height: 120, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: latest.map((e) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Container(height: (e.weight / maxW * 110).clamp(18, 110), decoration: BoxDecoration(color: seedColor.withValues(alpha: .75), borderRadius: BorderRadius.circular(14)))))).toList()))])); }
  Widget _entryTile(int i) { final e = entries[i]; return Padding(padding: const EdgeInsets.only(bottom: 10), child: ProCard(child: Row(children: [CircleAvatar(backgroundColor: seedColor.withValues(alpha: .12), child: const Icon(Icons.scale_rounded, color: seedColor)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${e.weight.toStringAsFixed(1)} كغم', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text('${_date(e.date)}${e.note.isEmpty ? '' : ' • ${e.note}'}', style: TextStyle(color: Colors.grey.shade700))])), IconButton(onPressed: () => _delete(i), icon: const Icon(Icons.delete_outline_rounded))]))); }
  Widget _tipCard() => ProCard(child: Row(children: [const Icon(Icons.lightbulb_rounded, color: warmColor), const SizedBox(width: 10), Expanded(child: Text(_message(), style: const TextStyle(fontWeight: FontWeight.w700)))]));
  String _message() => change <= 0 ? 'استمرارك أهم من سرعة النتائج. قياس واحد يوميًا يكفي.' : 'لا تقلق من التذبذب اليومي، المهم متابعة الاتجاه العام.';
  Widget _stat(String t, String v, IconData icon) => ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: seedColor), const SizedBox(height: 8), Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), Text(t)]));
  Widget _pageHeader(String title, String sub) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(sub, style: TextStyle(color: Colors.grey.shade700))]));
  Widget _sectionTitle(String s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(s, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));
  String _date(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

class ProCard extends StatelessWidget { final Widget child; const ProCard({super.key, required this.child}); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .055), blurRadius: 22, offset: const Offset(0, 10))]), child: child); }
