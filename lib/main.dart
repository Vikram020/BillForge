import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

void main() => runApp(const BillForgeApp());

enum InvoiceStatus { draft, sent, pending, paid, overdue, cancelled }
enum PaymentMethod { bankTransfer, card, cash, upi, other }

extension InvoiceStatusText on InvoiceStatus {
  String get text => switch (this) {
    InvoiceStatus.draft => 'Draft',
    InvoiceStatus.sent => 'Sent',
    InvoiceStatus.pending => 'Pending',
    InvoiceStatus.paid => 'Paid',
    InvoiceStatus.overdue => 'Overdue',
    InvoiceStatus.cancelled => 'Cancelled',
  };
}
extension PaymentMethodText on PaymentMethod {
  String get text => switch (this) {
    PaymentMethod.bankTransfer => 'Bank Transfer',
    PaymentMethod.card => 'Card',
    PaymentMethod.cash => 'Cash',
    PaymentMethod.upi => 'UPI',
    PaymentMethod.other => 'Other',
  };
}

class Client {
  String id, name, company, email, phone, address, taxId;
  Client({required this.id, required this.name, required this.company,
    required this.email, required this.phone, required this.address, this.taxId = ''});
}

class Product {
  String id, name, description, sku, category;
  double price, taxRate;
  Product({required this.id, required this.name, required this.description,
    required this.sku, required this.price, required this.taxRate, required this.category});
}

class Item {
  String id, description;
  double qty, rate, tax;
  Item({required this.id, required this.description, required this.qty,
    required this.rate, required this.tax});
  double get base => qty * rate;
  double get taxAmount => base * tax / 100;
  double get amount => base + taxAmount;
}

class Invoice {
  String id, number, currency, notes, terms, businessTaxId, placeOfSupply;
  Client client;
  DateTime issueDate, dueDate;
  List<Item> items;
  double discount;
  InvoiceStatus status;
  Invoice({required this.id, required this.number, required this.currency,
    required this.notes, required this.terms, required this.businessTaxId,
    required this.placeOfSupply, required this.client, required this.issueDate,
    required this.dueDate, required this.items, required this.discount, required this.status});
  double get subtotal => items.fold(0, (s, i) => s + i.base);
  double get tax => items.fold(0, (s, i) => s + i.taxAmount);
  double get total => subtotal - discount + tax;
}

class Payment {
  String id, invoiceId, reference;
  double amount;
  DateTime date;
  PaymentMethod method;
  Payment({required this.id, required this.invoiceId, required this.amount,
    required this.date, required this.method, required this.reference});
}

class Store extends ChangeNotifier {
  final clients = <Client>[
    Client(id:'c1', name:'Sarah Mitchell', company:'Acme Corporation', email:'sarah@acme.example', phone:'+1 555 0101', address:'100 Market Street, New York'),
    Client(id:'c2', name:'Daniel Roy', company:'BrightLabs', email:'daniel@brightlabs.example', phone:'+44 20 0000 0102', address:'42 King Street, London'),
    Client(id:'c3', name:'Priya Sharma', company:'Vertex Solutions', email:'priya@vertex.example', phone:'+91 98765 43210', address:'Salt Lake, Kolkata, India', taxId:'19ABCDE1234F1Z2'),
    Client(id:'c4', name:'Marcus Lee', company:'Northstar Labs', email:'marcus@northstar.example', phone:'+1 555 0104', address:'Austin, Texas'),
  ];
  final products = <Product>[
    Product(id:'p1', name:'Website Design', description:'Responsive marketing website design', sku:'WEB-001', price:1500, taxRate:18, category:'Design'),
    Product(id:'p2', name:'UI/UX Design', description:'Product interface design', sku:'UX-002', price:1200, taxRate:18, category:'Design'),
    Product(id:'p3', name:'SEO Consulting', description:'Monthly SEO consulting', sku:'SEO-003', price:800, taxRate:18, category:'Marketing'),
    Product(id:'p4', name:'Development', description:'Custom application development', sku:'DEV-004', price:2500, taxRate:18, category:'Development'),
    Product(id:'p5', name:'Monthly Retainer', description:'Ongoing consulting retainer', sku:'RET-005', price:3000, taxRate:18, category:'Consulting'),
  ];
  late final List<Invoice> invoices = _seed();
  final payments = <Payment>[];

  List<Invoice> _seed() {
    final n = DateTime.now();
    return [
      Invoice(id:'i1', number:'INV-1042', currency:'USD', notes:'Thank you for your business.',
        terms:'Payment due within 15 days.', businessTaxId:'19AAACP1234A1Z5', placeOfSupply:'West Bengal',
        client:clients[0], issueDate:n.subtract(const Duration(days:22)), dueDate:n.subtract(const Duration(days:7)),
        discount:200, status:InvoiceStatus.paid, items:[
          Item(id:'a', description:'Website Design', qty:1, rate:1500, tax:18),
          Item(id:'b', description:'Development', qty:1, rate:2500, tax:18)]),
      Invoice(id:'i2', number:'INV-1043', currency:'USD', notes:'Please include the invoice number with payment.',
        terms:'Payment due within 15 days.', businessTaxId:'19AAACP1234A1Z5', placeOfSupply:'West Bengal',
        client:clients[1], issueDate:n.subtract(const Duration(days:10)), dueDate:n.add(const Duration(days:5)),
        discount:0, status:InvoiceStatus.pending, items:[
          Item(id:'c', description:'UI/UX Design', qty:2, rate:1200, tax:18)]),
      Invoice(id:'i3', number:'INV-1044', currency:'USD', notes:'Thank you for your business.',
        terms:'Payment due within 15 days.', businessTaxId:'19AAACP1234A1Z5', placeOfSupply:'West Bengal',
        client:clients[2], issueDate:n.subtract(const Duration(days:40)), dueDate:n.subtract(const Duration(days:25)),
        discount:0, status:InvoiceStatus.overdue, items:[
          Item(id:'d', description:'SEO Consulting', qty:3, rate:800, tax:18)]),
      Invoice(id:'i4', number:'INV-1045', currency:'USD', notes:'Thank you for your business.',
        terms:'Payment due within 15 days.', businessTaxId:'19AAACP1234A1Z5', placeOfSupply:'West Bengal',
        client:clients[3], issueDate:n.subtract(const Duration(days:2)), dueDate:n.add(const Duration(days:13)),
        discount:0, status:InvoiceStatus.sent, items:[
          Item(id:'e', description:'Monthly Retainer', qty:1, rate:3000, tax:18)]),
    ];
  }

  void saveInvoice(Invoice x) {
    final i = invoices.indexWhere((a)=>a.id==x.id);
    if (i < 0) invoices.insert(0,x); else invoices[i]=x;
    notifyListeners();
  }
  void deleteInvoice(String id) { invoices.removeWhere((x)=>x.id==id); notifyListeners(); }
  void addPayment(Payment p) {
    payments.insert(0,p);
    final i=invoices.indexWhere((x)=>x.id==p.invoiceId);
    if(i>=0) {
      final inv=invoices[i];
      final paid=payments.where((x)=>x.invoiceId==inv.id).fold(0.0,(s,x)=>s+x.amount);
      if(paid>=inv.total) inv.status=InvoiceStatus.paid;
    }
    notifyListeners();
  }
}

final store = Store();

String money(double v, [String c='USD']) {
  final symbol = {'USD':'\$','INR':'₹','EUR':'€','GBP':'£'}[c] ?? c;
  return '$symbol${v.toStringAsFixed(2)}';
}
String date(DateTime d)=>DateFormat('dd MMM yyyy').format(d);

class BillForgeApp extends StatefulWidget {
  const BillForgeApp({super.key});
  @override State<BillForgeApp> createState()=>_AppState();
}
class _AppState extends State<BillForgeApp> {
  ThemeMode mode=ThemeMode.light;
  @override Widget build(BuildContext context)=>AnimatedBuilder(
    animation:store,
    builder:(_,__)=>MaterialApp(
      debugShowCheckedModeBanner:false, title:'BillForge', themeMode:mode,
      theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF635BFF)),scaffoldBackgroundColor:const Color(0xFFF7F8FA),fontFamily:'Arial'),
      darkTheme:ThemeData(useMaterial3:true,brightness:Brightness.dark,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF8B83FF),brightness:Brightness.dark),fontFamily:'Arial'),
      home:Shell(toggleTheme:()=>setState(()=>mode=mode==ThemeMode.light?ThemeMode.dark:ThemeMode.light)),
    ));
}

class Shell extends StatefulWidget {
  final VoidCallback toggleTheme;
  const Shell({super.key,required this.toggleTheme});
  @override State<Shell> createState()=>_ShellState();
}
class _ShellState extends State<Shell> {
  int tab=0;
  final names=['Dashboard','Invoices','Clients','Products & Services','Payments','Reports','Settings'];
  final icons=[Icons.grid_view_rounded,Icons.receipt_long_rounded,Icons.people_alt_outlined,Icons.inventory_2_outlined,Icons.payments_outlined,Icons.bar_chart_rounded,Icons.settings_outlined];
  Widget screen()=>switch(tab){
    0=>const Dashboard(),
    1=>const Invoices(),
    2=>const Clients(),
    3=>const Products(),
    4=>const Payments(),
    5=>const Reports(),
    _=>const Settings(),
  };
  @override Widget build(BuildContext context){
    final wide=MediaQuery.sizeOf(context).width>=900;
    return Scaffold(
      drawer:wide?null:Drawer(child:nav(drawer:true)),
      body:Row(children:[if(wide) nav(),Expanded(child:Column(children:[
        AppBar(title:Text(names[tab],style:const TextStyle(fontWeight:FontWeight.w800)),leading:wide?null:IconButton(onPressed:()=>Scaffold.of(context).openDrawer,icon:const Icon(Icons.menu)),actions:[
          IconButton(onPressed:widget.toggleTheme,icon:const Icon(Icons.brightness_6_outlined)),
          IconButton(onPressed:()=>msg(context,'Notifications'),icon:const Icon(Icons.notifications_none_rounded)),
        ]),
        Expanded(child:screen())
      ]))]),
      bottomNavigationBar:wide?null:NavigationBar(selectedIndex:tab>4?0:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[
        NavigationDestination(icon:Icon(Icons.grid_view_rounded),label:'Home'),
        NavigationDestination(icon:Icon(Icons.receipt_long),label:'Invoices'),
        NavigationDestination(icon:Icon(Icons.people_outline),label:'Clients'),
        NavigationDestination(icon:Icon(Icons.payments_outlined),label:'Payments'),
        NavigationDestination(icon:Icon(Icons.bar_chart),label:'Reports'),
      ]),
    );
  }
  Widget nav({bool drawer=false})=>Container(width:250,padding:const EdgeInsets.all(16),color:Theme.of(context).colorScheme.surface,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const SizedBox(height:8),Row(children:[Container(width:38,height:38,decoration:BoxDecoration(color:Theme.of(context).colorScheme.primary,borderRadius:BorderRadius.circular(11)),child:const Icon(Icons.receipt_long,color:Colors.white)),const SizedBox(width:10),const Text('BillForge',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900))]),
    const SizedBox(height:28),Text('WORKSPACE',style:TextStyle(fontSize:11,letterSpacing:1.2,color:Theme.of(context).hintColor,fontWeight:FontWeight.w700)),
    const SizedBox(height:8),...List.generate(names.length,(i)=>Padding(padding:const EdgeInsets.only(bottom:4),child:ListTile(dense:true,selected:i==tab,selectedTileColor:Theme.of(context).colorScheme.primary.withValues(alpha:.10),leading:Icon(icons[i]),title:Text(names[i]),onTap:(){setState(()=>tab=i);if(drawer)Navigator.pop(context);}))),
    const Spacer(),const ListTile(leading:CircleAvatar(radius:18,child:Text('PS',style:TextStyle(fontSize:11))),title:Text('PixelCraft Studio'),subtitle:Text('Admin'))
  ]));
}

class CardBox extends StatelessWidget {
  final Widget child; const CardBox({super.key,required this.child});
  @override Widget build(BuildContext context)=>Card(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18),side:BorderSide(color:Theme.of(context).dividerColor)),child:Padding(padding:const EdgeInsets.all(20),child:child));
}
class Badge extends StatelessWidget {
  final InvoiceStatus status; const Badge({super.key,required this.status});
  @override Widget build(BuildContext context){final c=switch(status){InvoiceStatus.paid=>Colors.green,InvoiceStatus.overdue=>Colors.red,InvoiceStatus.pending=>Colors.orange,InvoiceStatus.sent=>Colors.blue,_=>Colors.grey};return Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:c.withValues(alpha:.10),borderRadius:BorderRadius.circular(99)),child:Text(status.text,style:TextStyle(color:c,fontSize:12,fontWeight:FontWeight.w800)));}}
void msg(BuildContext c,String x)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(x)));

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  @override Widget build(BuildContext context){
    final rev=store.invoices.where((x)=>x.status==InvoiceStatus.paid).fold(0.0,(s,x)=>s+x.total);
    final out=store.invoices.where((x)=>[InvoiceStatus.pending,InvoiceStatus.sent,InvoiceStatus.overdue].contains(x.status)).fold(0.0,(s,x)=>s+x.total);
    final over=store.invoices.where((x)=>x.status==InvoiceStatus.overdue).fold(0.0,(s,x)=>s+x.total);
    return ListView(padding:const EdgeInsets.all(24),children:[
      Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Good evening 👋',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),Text("Here's what's happening with your business.",style:TextStyle(color:Theme.of(context).hintColor))])),FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const Editor())),icon:const Icon(Icons.add),label:const Text('Create Invoice'))]),
      const SizedBox(height:22),
      LayoutBuilder(builder:(c,box){final one=box.maxWidth<700;final cards=[stat('Total Revenue',money(rev),Icons.trending_up),stat('Outstanding',money(out),Icons.schedule),stat('Paid Invoices','${store.invoices.where((x)=>x.status==InvoiceStatus.paid).length}',Icons.check_circle_outline),stat('Overdue',money(over),Icons.warning_amber)];return one?Column(children:cards.map((x)=>Padding(padding:const EdgeInsets.only(bottom:12),child:x)).toList()):Row(children:cards.map((x)=>Expanded(child:Padding(padding:const EdgeInsets.only(right:12),child:x))).toList());}),
      const SizedBox(height:20),LayoutBuilder(builder:(c,b)=>b.maxWidth<850?Column(children:[chart(),const SizedBox(height:20),overview()]):Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:2,child:chart()),const SizedBox(width:20),Expanded(child:overview())])),
      const SizedBox(height:20),CardBox(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Recent invoices',style:TextStyle(fontWeight:FontWeight.w900,fontSize:17)),const SizedBox(height:12),...store.invoices.map((x)=>ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(child:Text(x.number.substring(4,6))),title:Text('${x.number} · ${x.client.company}',style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(date(x.issueDate)),trailing:Wrap(spacing:12,children:[Badge(status:x.status),Text(money(x.total,x.currency),style:const TextStyle(fontWeight:FontWeight.w800))])))]))
    ]);
  }
  Widget stat(String a,String b,IconData i)=>CardBox(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i),const SizedBox(height:15),Text(a,style:const TextStyle(fontSize:12)),const SizedBox(height:4),Text(b,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const Text('+12.8%',style:TextStyle(color:Colors.green,fontWeight:FontWeight.w700,fontSize:12))]));
  Widget chart()=>CardBox(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Revenue',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:20),SizedBox(height:250,child:LineChart(LineChartData(gridData:const FlGridData(show:false),borderData:FlBorderData(show:false),titlesData:const FlTitlesData(topTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),rightTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),leftTitles:AxisTitles(sideTitles:SideTitles(showTitles:false))),lineBarsData:[LineChartBarData(isCurved:true,barWidth:3,dotData:const FlDotData(show:false),spots:const[FlSpot(0,2),FlSpot(1,3),FlSpot(2,2.8),FlSpot(3,5),FlSpot(4,4),FlSpot(5,7),FlSpot(6,6),FlSpot(7,8),FlSpot(8,7),FlSpot(9,9),FlSpot(10,8),FlSpot(11,10)])]))) ]));
  Widget overview()=>CardBox(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Invoice overview',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:20),SizedBox(height:180,child:PieChart(PieChartData(centerSpaceRadius:45,sections:[PieChartSectionData(value:store.invoices.where((x)=>x.status==InvoiceStatus.paid).length.toDouble(),title:'Paid',radius:55),PieChartSectionData(value:store.invoices.where((x)=>x.status==InvoiceStatus.pending).length.toDouble(),title:'Pending',radius:55),PieChartSectionData(value:store.invoices.where((x)=>x.status==InvoiceStatus.overdue).length.toDouble(),title:'Overdue',radius:55)]))) ]));
}

class Invoices extends StatefulWidget {const Invoices({super.key});@override State<Invoices> createState()=>_InvoicesState();}
class _InvoicesState extends State<Invoices>{String q='';InvoiceStatus? filter;
@override Widget build(BuildContext context){final list=store.invoices.where((x)=>(q.isEmpty||x.number.toLowerCase().contains(q.toLowerCase())||x.client.company.toLowerCase().contains(q.toLowerCase()))&&(filter==null||x.status==filter)).toList();return ListView(padding:const EdgeInsets.all(24),children:[
Row(children:[const Expanded(child:Text('Invoices',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const Editor())),icon:const Icon(Icons.add),label:const Text('New Invoice'))]),
const SizedBox(height:18),CardBox(child:Row(children:[Expanded(child:TextField(onChanged:(v)=>setState(()=>q=v),decoration:const InputDecoration(hintText:'Search invoices or clients...',prefixIcon:Icon(Icons.search),border:InputBorder.none))),DropdownButton<InvoiceStatus?>(value:filter,hint:const Text('All statuses'),underline:const SizedBox(),items:[const DropdownMenuItem(value:null,child:Text('All statuses')),...InvoiceStatus.values.map((s)=>DropdownMenuItem(value:s,child:Text(s.text)))],onChanged:(v)=>setState(()=>filter=v))])),
const SizedBox(height:16),CardBox(child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(columns:const[DataColumn(label:Text('Invoice')),DataColumn(label:Text('Client')),DataColumn(label:Text('Issue')),DataColumn(label:Text('Due')),DataColumn(label:Text('Amount')),DataColumn(label:Text('Status')),DataColumn(label:Text(''))],rows:list.map((x)=>DataRow(cells:[DataCell(Text(x.number,style:const TextStyle(fontWeight:FontWeight.w800))),DataCell(Text(x.client.company)),DataCell(Text(date(x.issueDate))),DataCell(Text(date(x.dueDate))),DataCell(Text(money(x.total,x.currency))),DataCell(Badge(status:x.status)),DataCell(PopupMenuButton<String>(onSelected:(v){if(v=='edit')Navigator.push(context,MaterialPageRoute(builder:(_)=>Editor(invoice:x)));if(v=='delete'){store.deleteInvoice(x.id);}},itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('View / Edit')),PopupMenuItem(value:'delete',child:Text('Delete'))]))])).toList())))]);}}

class Editor extends StatefulWidget {
  final Invoice? invoice;
  const Editor({super.key, this.invoice});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  late Invoice x;
  late List<Item> items;
  late Client client;
  late TextEditingController discount, notes, terms;

  @override
  void initState() {
    super.initState();
    x = widget.invoice ?? Invoice(
      id: 'i${DateTime.now().millisecondsSinceEpoch}',
      number: 'INV-${1046 + store.invoices.length}',
      currency: 'USD',
      notes: 'Thank you for your business.',
      terms: 'Payment due within 15 days.',
      businessTaxId: '19AAACP1234A1Z5',
      placeOfSupply: 'West Bengal',
      client: store.clients.first,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 15)),
      items: [],
      discount: 0,
      status: InvoiceStatus.draft,
    );
    client = x.client;
    items = List.of(x.items);
    discount = TextEditingController(text: x.discount.toString());
    notes = TextEditingController(text: x.notes);
    terms = TextEditingController(text: x.terms);
  }

  @override
  void dispose() {
    discount.dispose();
    notes.dispose();
    terms.dispose();
    super.dispose();
  }

  double get sub => items.fold(0, (s, i) => s + i.base);
  double get tax => items.fold(0, (s, i) => s + i.taxAmount);
  double get total => sub - (double.tryParse(discount.text) ?? 0) + tax;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'Create Invoice' : 'Edit ${x.number}'),
        actions: [TextButton(onPressed: save, child: const Text('Save Draft'))],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = constraints.maxWidth < 1000
              ? Column(children: [form(), const SizedBox(height: 20), preview()])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: form()),
                    const SizedBox(width: 24),
                    SizedBox(width: 480, child: preview()),
                  ],
                );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: content,
          );
        },
      ),
    );
  }

  Widget form() {
    return Column(
      children: [
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Invoice details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: x.number,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Invoice number'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ListTile(
                      title: const Text('Due date'),
                      subtitle: Text(date(x.dueDate)),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: pickDue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bill to', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              DropdownButtonFormField<Client>(
                value: client,
                decoration: const InputDecoration(labelText: 'Client'),
                items: store.clients
                    .map((c) => DropdownMenuItem(value: c, child: Text('${c.company} · ${c.name}')))
                    .toList(),
                onChanged: (v) => setState(() => client = v!),
              ),
              const SizedBox(height: 10),
              Text(client.email),
              Text(client.address),
              if (client.taxId.isNotEmpty) Text('GSTIN: ${client.taxId}'),
            ],
          ),
        ),
        const SizedBox(height: 15),
        CardBox(
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Line items', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                  OutlinedButton.icon(
                    onPressed: addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.asMap().entries.map((e) => itemEditor(e.key, e.value)),
            ],
          ),
        ),
        const SizedBox(height: 15),
        CardBox(
          child: Column(
            children: [
              TextField(
                controller: discount,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Discount'),
              ),
              const SizedBox(height: 12),
              TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 12),
              TextField(controller: terms, maxLines: 2, decoration: const InputDecoration(labelText: 'Payment terms')),
            ],
          ),
        ),
      ],
    );
  }

  Widget itemEditor(int i, Item it) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: it.description,
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (v) => setState(() => it.description = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: '${it.qty}',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qty'),
                onChanged: (v) => setState(() => it.qty = double.tryParse(v) ?? 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: '${it.rate}',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Rate'),
                onChanged: (v) => setState(() => it.rate = double.tryParse(v) ?? 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: '${it.tax}',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tax %'),
                onChanged: (v) => setState(() => it.tax = double.tryParse(v) ?? 0),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => items.removeAt(i)),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget preview() {
    return CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PixelCraft Studio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text('INVOICE\\n${x.number}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const Text('hello@pixelcraft.example'),
          const Text('12 Park Street, Kolkata, India'),
          const Divider(height: 30),
          const Text('BILL TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          Text(client.company, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(client.name),
          Text(client.email),
          Text(client.address),
          const SizedBox(height: 18),
          ...items.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(i.description)),
                  Text('${i.qty} × ${money(i.rate, x.currency)}'),
                  const SizedBox(width: 10),
                  Text(money(i.amount, x.currency), style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const Divider(height: 25),
          row('Subtotal', sub),
          row('Discount', -(double.tryParse(discount.text) ?? 0)),
          row('Tax', tax),
          const SizedBox(height: 8),
          row('Total', total, strong: true),
          const SizedBox(height: 20),
          Text(notes.text),
          const SizedBox(height: 8),
          Text(terms.text, style: TextStyle(color: Theme.of(context).hintColor)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => msg(context, 'PDF generation can be added next.'),
                  child: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(onPressed: send, child: const Text('Send Invoice'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget row(String a, double v, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Spacer(),
          SizedBox(width: 80, child: Text(a)),
          SizedBox(
            width: 110,
            child: Text(
              money(v, x.currency),
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: strong ? FontWeight.w900 : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  void addItem() {
    final p = store.products.first;
    setState(() => items.add(Item(
      id: 'it${DateTime.now().microsecondsSinceEpoch}',
      description: p.name,
      qty: 1,
      rate: p.price,
      tax: p.taxRate,
    )));
  }

  Future<void> pickDue() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: x.dueDate,
    );
    if (d != null) setState(() => x.dueDate = d);
  }

  void save() {
    x.items = items;
    x.client = client;
    x.discount = double.tryParse(discount.text) ?? 0;
    x.notes = notes.text;
    x.terms = terms.text;
    store.saveInvoice(x);
    msg(context, 'Invoice saved');
  }

  void send() {
    x.items = items;
    x.client = client;
    x.discount = double.tryParse(discount.text) ?? 0;
    x.notes = notes.text;
    x.terms = terms.text;
    x.status = InvoiceStatus.sent;
    store.saveInvoice(x);
    msg(context, 'Invoice sent');
  }
}

class Clients extends StatefulWidget{const Clients({super.key});@override State<Clients>createState()=>_ClientsState();}
class _ClientsState extends State<Clients>{String q='';@override Widget build(BuildContext context){final list=store.clients.where((c)=>c.company.toLowerCase().contains(q.toLowerCase())||c.name.toLowerCase().contains(q.toLowerCase())).toList();return ListView(padding:const EdgeInsets.all(24),children:[Row(children:[const Expanded(child:Text('Clients',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:()=>form(context),icon:const Icon(Icons.add),label:const Text('Add Client'))]),const SizedBox(height:18),CardBox(child:TextField(onChanged:(v)=>setState(()=>q=v),decoration:const InputDecoration(hintText:'Search clients...',prefixIcon:Icon(Icons.search),border:InputBorder.none))),const SizedBox(height:16),GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:list.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:MediaQuery.sizeOf(context).width>1100?3:MediaQuery.sizeOf(context).width>700?2:1,crossAxisSpacing:16,mainAxisSpacing:16,childAspectRatio:1.6),itemBuilder:(_,i){final c=list[i];final inv=store.invoices.where((x)=>x.client.id==c.id);final billed=inv.fold(0.0,(s,x)=>s+x.total);return CardBox(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[CircleAvatar(child:Text(c.company[0])),const SizedBox(width:10),Expanded(child:Text(c.company,style:const TextStyle(fontWeight:FontWeight.w900))),IconButton(onPressed:()=>form(context,old:c),icon:const Icon(Icons.edit_outlined))]),Text(c.name),Text(c.email),const Spacer(),Text('${inv.length} invoices · ${money(billed)}',style:const TextStyle(fontWeight:FontWeight.w700))]));})]);}
void form(BuildContext context,{Client? old}){final n=TextEditingController(text:old?.name),co=TextEditingController(text:old?.company),e=TextEditingController(text:old?.email),p=TextEditingController(text:old?.phone),a=TextEditingController(text:old?.address);showDialog(context:context,builder:(d)=>AlertDialog(title:Text(old==null?'Add client':'Edit client'),content:SizedBox(width:450,child:SingleChildScrollView(child:Column(children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Contact name')),TextField(controller:co,decoration:const InputDecoration(labelText:'Company')),TextField(controller:e,decoration:const InputDecoration(labelText:'Email')),TextField(controller:p,decoration:const InputDecoration(labelText:'Phone')),TextField(controller:a,decoration:const InputDecoration(labelText:'Address'))]))),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:(){final c=old??Client(id:'c${DateTime.now().millisecondsSinceEpoch}',name:n.text,company:co.text,email:e.text,phone:p.text,address:a.text);c.name=n.text;c.company=co.text;c.email=e.text;c.phone=p.text;c.address=a.text;if(old==null)store.clients.add(c);store.notifyListeners();Navigator.pop(d);},child:const Text('Save'))]));}}

class Products extends StatelessWidget{const Products({super.key});@override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(24),children:[Row(children:[const Expanded(child:Text('Products & Services',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:()=>msg(context,'Add product form is ready for the next backend phase.'),icon:const Icon(Icons.add),label:const Text('Add Product'))]),const SizedBox(height:18),CardBox(child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(columns:const[DataColumn(label:Text('Name')),DataColumn(label:Text('SKU')),DataColumn(label:Text('Category')),DataColumn(label:Text('Price')),DataColumn(label:Text('Tax'))],rows:store.products.map((p)=>DataRow(cells:[DataCell(Text(p.name,style:const TextStyle(fontWeight:FontWeight.w800))),DataCell(Text(p.sku)),DataCell(Text(p.category)),DataCell(Text(money(p.price))),DataCell(Text('${p.taxRate}%'))])).toList()))) ]);}

class Payments extends StatelessWidget{const Payments({super.key});@override Widget build(BuildContext context){final received=store.payments.fold(0.0,(s,p)=>s+p.amount);final pending=store.invoices.where((x)=>x.status==InvoiceStatus.pending).fold(0.0,(s,x)=>s+x.total);final overdue=store.invoices.where((x)=>x.status==InvoiceStatus.overdue).fold(0.0,(s,x)=>s+x.total);return ListView(padding:const EdgeInsets.all(24),children:[Row(children:[const Expanded(child:Text('Payments',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:()=>record(context),icon:const Icon(Icons.add),label:const Text('Record Payment'))]),const SizedBox(height:18),Row(children:[Expanded(child:stat('Received',received)),const SizedBox(width:12),Expanded(child:stat('Pending',pending)),const SizedBox(width:12),Expanded(child:stat('Overdue',overdue))]),const SizedBox(height:18),CardBox(child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(columns:const[DataColumn(label:Text('Payment')),DataColumn(label:Text('Invoice')),DataColumn(label:Text('Date')),DataColumn(label:Text('Method')),DataColumn(label:Text('Amount'))],rows:store.payments.map((p){final i=store.invoices.firstWhere((x)=>x.id==p.invoiceId);return DataRow(cells:[DataCell(Text(p.id.toUpperCase())),DataCell(Text(i.number)),DataCell(Text(date(p.date))),DataCell(Text(p.method.text)),DataCell(Text(money(p.amount,i.currency))) ]);}).toList()))) ]);}
Widget stat(String a,double v)=>CardBox(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a),const SizedBox(height:5),Text(money(v),style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900))]));
void record(BuildContext context){Invoice inv=store.invoices.first;final amount=TextEditingController(text:inv.total.toStringAsFixed(2));PaymentMethod method=PaymentMethod.bankTransfer;showDialog(context:context,builder:(d)=>StatefulBuilder(builder:(c,set)=>AlertDialog(title:const Text('Record payment'),content:SizedBox(width:430,child:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<Invoice>(value:inv,items:store.invoices.map((i)=>DropdownMenuItem(value:i,child:Text(i.number))).toList(),onChanged:(v)=>set(()=>inv=v!),decoration:const InputDecoration(labelText:'Invoice')),TextField(controller:amount,decoration:const InputDecoration(labelText:'Amount')),DropdownButtonFormField<PaymentMethod>(value:method,items:PaymentMethod.values.map((m)=>DropdownMenuItem(value:m,child:Text(m.text))).toList(),onChanged:(v)=>set(()=>method=v!),decoration:const InputDecoration(labelText:'Method'))])),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:(){store.addPayment(Payment(id:'pay${DateTime.now().millisecondsSinceEpoch}',invoiceId:inv.id,amount:double.tryParse(amount.text)??0,date:DateTime.now(),method:method,reference:'MANUAL'));Navigator.pop(d);},child:const Text('Save'))])));}}

class Reports extends StatelessWidget {
  const Reports({super.key});

  @override
  Widget build(BuildContext context) {
    final revenue = store.invoices
        .where((x) => x.status == InvoiceStatus.paid)
        .fold(0.0, (s, x) => s + x.total);
    final outstanding = store.invoices
        .where((x) => x.status != InvoiceStatus.paid && x.status != InvoiceStatus.draft)
        .fold(0.0, (s, x) => s + x.total);
    final tax = store.invoices.fold(0.0, (s, x) => s + x.tax);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Reports', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const Text('Business performance at a glance.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: CardBox(child: Text('Revenue\\n${money(revenue)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)))),
            const SizedBox(width: 12),
            Expanded(child: CardBox(child: Text('Outstanding\\n${money(outstanding)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)))),
            const SizedBox(width: 12),
            Expanded(child: CardBox(child: Text('Tax\\n${money(tax)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)))),
          ],
        ),
        const SizedBox(height: 20),
        CardBox(
          child: SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(
                  12,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: [3, 4, 5, 4, 7, 6, 8, 7, 9, 8, 10, 12][i].toDouble(),
                        width: 15,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Settings extends StatefulWidget{const Settings({super.key});@override State<Settings>createState()=>_SettingsState();}
class _SettingsState extends State<Settings>{bool tax=true,notify=true;String currency='USD',terms='15 days';@override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(24),children:[const Text('Settings',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900)),Text('Business and invoice preferences.',style:TextStyle(color:Colors.grey)),const SizedBox(height:18),CardBox(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Business profile',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)),TextFormField(initialValue:'PixelCraft Studio',decoration:const InputDecoration(labelText:'Business name')),TextFormField(initialValue:'hello@pixelcraft.example',decoration:const InputDecoration(labelText:'Email')),TextFormField(initialValue:'12 Park Street, Kolkata, India',decoration:const InputDecoration(labelText:'Address')),TextFormField(initialValue:'19AAACP1234A1Z5',decoration:const InputDecoration(labelText:'GSTIN / Tax ID'))])),const SizedBox(height:15),CardBox(child:Column(children:[const Align(alignment:Alignment.centerLeft,child:Text('Invoice & Tax',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900))),DropdownButtonFormField<String>(value:currency,items:const[DropdownMenuItem(value:'USD',child:Text('USD — US Dollar')),DropdownMenuItem(value:'INR',child:Text('INR — Indian Rupee')),DropdownMenuItem(value:'EUR',child:Text('EUR — Euro')),DropdownMenuItem(value:'GBP',child:Text('GBP — Pound Sterling'))],onChanged:(v)=>setState(()=>currency=v!),decoration:const InputDecoration(labelText:'Default currency')),DropdownButtonFormField<String>(value:terms,items:const[DropdownMenuItem(value:'Due on receipt',child:Text('Due on receipt')),DropdownMenuItem(value:'15 days',child:Text('15 days')),DropdownMenuItem(value:'30 days',child:Text('30 days'))],onChanged:(v)=>setState(()=>terms=v!),decoration:const InputDecoration(labelText:'Payment terms')),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Enable tax'),value:tax,onChanged:(v)=>setState(()=>tax=v)),const ListTile(contentPadding:EdgeInsets.zero,title:Text('GST support'),subtitle:Text('CGST, SGST, IGST, HSN/SAC, place of supply and reverse-charge fields are ready for backend implementation.'))])),const SizedBox(height:15),CardBox(child:SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Payment notifications'),value:notify,onChanged:(v)=>setState(()=>notify=v))) ]);}

