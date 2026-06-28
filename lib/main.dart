
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SmartApp());

const String appTitle = 'متابعة الوزن';
const String appIcon = '⚖️';
const Color seedColor = Color(0xFF0891B2);
const String appMode = 'weight';
const String developerEmail = 'fastunlocked2017@gmail.com';

class SmartApp extends StatelessWidget {
  const SmartApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
        fontFamily: 'Arial',
      ),
      home: const Directionality(textDirection: TextDirection.rtl, child: HomeScreen()),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final TextEditingController input = TextEditingController();
  final TextEditingController second = TextEditingController();
  List<String> items = [];
  double value = 75;
  double target = 70;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      items = p.getStringList('items') ?? _starterItems();
      value = p.getDouble('value') ?? 75;
      target = p.getDouble('target') ?? 70;
    });
  }
  List<String> _starterItems() {
    switch(appMode){
      case 'shopping': return ['خبز', 'حليب', 'خضار'];
      case 'notes': return ['فكرة مهمة', 'موعد يجب تذكره'];
      case 'weight': return ['75.0 كغم', '74.6 كغم'];
      case 'measure': return ['120 سم', '2.5 متر'];
      case 'qrgen': return ['https://example.com'];
      case 'qrread': return ['نتيجة تجريبية'];
    }
    return [];
  }
  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('items', items);
    await p.setDouble('value', value);
    await p.setDouble('target', target);
  }
  void _sound([bool alert=false]) { SystemSound.play(alert ? SystemSoundType.alert : SystemSoundType.click); }
  void _add() {
    final text = input.text.trim();
    if (text.isEmpty) return;
    setState(() { items.insert(0, appMode == 'weight' ? '$text كغم' : appMode == 'measure' ? '$text سم' : text); input.clear(); });
    _save(); _sound();
  }
  void _delete(int i){ setState(()=>items.removeAt(i)); _save(); _sound(true); }

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _developer()];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v){ setState(()=>index=v); _sound(); },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.support_agent_rounded), label: 'المطور'),
        ],
      ),
    );
  }

  Widget _dashboard(){
    return CustomScrollView(slivers:[
      SliverToBoxAdapter(child: _hero()),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(18), child: _bodyByMode())),
    ]);
  }

  Widget _hero(){
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [seedColor, Color.lerp(seedColor, Colors.black, .22)!], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: seedColor.withValues(alpha:.24), blurRadius: 26, offset: const Offset(0, 14))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Row(children:[
          Container(width:64,height:64,alignment:Alignment.center,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.2),borderRadius:BorderRadius.circular(22)),child:Text(appIcon,style:const TextStyle(fontSize:34))),
          const SizedBox(width:14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
            Text(appTitle,style:const TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.w900)),
            const SizedBox(height:6),
            Text(_subtitle(),style:TextStyle(color:Colors.white.withValues(alpha:.86),fontSize:14,height:1.4)),
          ])),
        ]),
        const SizedBox(height:18),
        Row(children:[_mini('العناصر', '${items.length}'), const SizedBox(width:10), _mini('الوضع', _modeName())]),
      ]),
    );
  }
  Widget _mini(String a,String b)=>Expanded(child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.16),borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:TextStyle(color:Colors.white.withValues(alpha:.8),fontSize:12)),Text(b,style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold))])));
  String _subtitle(){
    switch(appMode){case 'shopping': return 'رتب مشترياتك بسرعة وعلّم العناصر المنجزة بصوت خفيف.'; case 'notes': return 'دفتر أنيق للأفكار اليومية والملاحظات السريعة.'; case 'weight': return 'سجل وزنك وتابع الفرق عن الهدف بشكل بسيط.'; case 'qrgen': return 'اكتب النص وشاهد شكل QR مبسط للحفظ والمراجعة.'; case 'measure': return 'سجل القياسات اليومية بطريقة مرتبة وواضحة.'; case 'qrread': return 'نسخة خفيفة لتسجيل نتائج المسح يدويًا قبل إضافة الكاميرا.';} return '';}
  String _modeName(){ switch(appMode){case 'shopping': return 'تسوق'; case 'notes': return 'ملاحظات'; case 'weight': return 'صحة'; case 'qrgen': return 'توليد'; case 'measure': return 'قياس'; case 'qrread': return 'مسح';} return '';}

  Widget _bodyByMode(){
    if(appMode=='weight') return _weightBody();
    if(appMode=='qrgen') return _qrGeneratorBody();
    return Column(children:[_inputCard(), const SizedBox(height:16), ...List.generate(items.length, (i)=>_itemCard(i))]);
  }
  Widget _inputCard(){
    final hint = appMode=='shopping'?'أضف غرضًا جديدًا':appMode=='notes'?'اكتب ملاحظة جديدة':appMode=='measure'?'أدخل القياس بالسنتمتر':appMode=='qrread'?'الصق نتيجة QR هنا':'أدخل قيمة';
    return CardBox(child: Row(children:[Expanded(child:TextField(controller:input,keyboardType: appMode=='measure'?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:hint,border:InputBorder.none))),FilledButton.icon(onPressed:_add,icon:const Icon(Icons.add_rounded),label:const Text('إضافة'))]));
  }
  Widget _itemCard(int i){
    final icon = appMode=='shopping'?Icons.shopping_bag_rounded:appMode=='notes'?Icons.sticky_note_2_rounded:appMode=='measure'?Icons.straighten_rounded:Icons.qr_code_scanner_rounded;
    return Padding(padding:const EdgeInsets.only(bottom:10),child:CardBox(child:Row(children:[CircleAvatar(backgroundColor:seedColor.withValues(alpha:.12),child:Icon(icon,color:seedColor)),const SizedBox(width:12),Expanded(child:Text(items[i],style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700))),IconButton(onPressed:()=>_delete(i),icon:const Icon(Icons.delete_outline_rounded))])));
  }
  Widget _weightBody(){
    return Column(children:[
      CardBox(child: Column(children:[
        Row(children:[Expanded(child:_numberField('الوزن الحالي', value, (v)=>value=v)), const SizedBox(width:10), Expanded(child:_numberField('الهدف', target, (v)=>target=v))]),
        const SizedBox(height:16),
        FilledButton.icon(onPressed:(){setState(()=>items.insert(0,'${value.toStringAsFixed(1)} كغم'));_save();_sound();}, icon:const Icon(Icons.save_rounded), label:const Text('حفظ الوزن')),
      ])),
      const SizedBox(height:16),
      CardBox(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('الفارق عن الهدف',style:TextStyle(color:seedColor,fontWeight:FontWeight.bold)),const SizedBox(height:10),Text('${(value-target).abs().toStringAsFixed(1)} كغم',style:const TextStyle(fontSize:34,fontWeight:FontWeight.w900)), LinearProgressIndicator(value:(target/value).clamp(.05,1),minHeight:12,borderRadius:BorderRadius.circular(20))])),
      const SizedBox(height:16), ...List.generate(items.length,(i)=>_itemCard(i))]);
  }
  Widget _numberField(String label,double current,ValueChanged<double> set){return TextField(key:ValueKey(label),keyboardType:TextInputType.number,decoration:InputDecoration(labelText:label,filled:true,fillColor:seedColor.withValues(alpha:.06),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none),hintText:current.toStringAsFixed(1)),onChanged:(s){final v=double.tryParse(s); if(v!=null){set(v);_save();}});} 
  Widget _qrGeneratorBody(){
    final data = input.text.isEmpty ? (items.isEmpty?'QR':items.first) : input.text;
    return Column(children:[_inputCard(),const SizedBox(height:18),CardBox(child:Column(children:[Text('معاينة QR مبسطة',style:TextStyle(color:seedColor,fontWeight:FontWeight.bold)),const SizedBox(height:16),CustomPaint(size:const Size(210,210),painter:QrLikePainter(data, seedColor)),const SizedBox(height:12),FilledButton.icon(onPressed:(){Clipboard.setData(ClipboardData(text:data));_sound();ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم النسخ')));},icon:const Icon(Icons.copy_rounded),label:const Text('نسخ النص'))])),const SizedBox(height:16),...List.generate(items.length,(i)=>_itemCard(i))]);
  }
  Widget _developer(){
    final msg='ملاحظة حول تطبيق $appTitle:\n';
    return SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[_hero(),CardBox(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('مراسلة المطور',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:10),const Text('انسخ الرسالة وأرسلها من بريدك عند الحاجة.'),const SizedBox(height:12),SelectableText(developerEmail,style:TextStyle(color:seedColor,fontWeight:FontWeight.bold)),const SizedBox(height:16),FilledButton.icon(onPressed:(){Clipboard.setData(ClipboardData(text:'$msg\n$developerEmail'));_sound();ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم نسخ الرسالة')));},icon:const Icon(Icons.copy_all_rounded),label:const Text('نسخ رسالة للمطور'))]))])));
  }
}

class CardBox extends StatelessWidget{ final Widget child; const CardBox({super.key,required this.child}); @override Widget build(BuildContext context)=>Container(width:double.infinity,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.06),blurRadius:22,offset:const Offset(0,10))]),child:child);}
class QrLikePainter extends CustomPainter{ final String data; final Color color; QrLikePainter(this.data,this.color); @override void paint(Canvas canvas,Size size){final p=Paint()..color=color; final bg=Paint()..color=Colors.white; canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero&size,const Radius.circular(18)),bg); final n=17; final cell=size.width/n; int seed=data.codeUnits.fold(7,(a,b)=>a+b); for(int y=0;y<n;y++){for(int x=0;x<n;x++){final fixed=(x<5&&y<5)||(x>11&&y<5)||(x<5&&y>11); final on=fixed||((x*y+seed+x+y)%4==0); if(on){canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x*cell+2,y*cell+2,cell-4,cell-4),const Radius.circular(3)),p);}}}} @override bool shouldRepaint(covariant QrLikePainter old)=>old.data!=data;}
