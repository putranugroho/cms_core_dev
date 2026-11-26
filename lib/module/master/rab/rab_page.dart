import 'package:cms_core/models/index.dart';
import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/ao_repository.dart';
import 'package:cms_core/repository/hris_repository.dart';
import 'package:cms_core/repository/rab_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/currency_formatted.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RabMarketingPage extends StatelessWidget {
  const RabMarketingPage({super.key});
  @override Widget build(BuildContext context) => const RabPage(marketing: true);
}

class RabKantorPage extends StatelessWidget {
  const RabKantorPage({super.key});
  @override Widget build(BuildContext context) => const RabPage(marketing: false);
}

class RabPage extends StatefulWidget {
  final bool marketing;
  const RabPage({super.key, required this.marketing});
  @override State<RabPage> createState() => _RabPageState();
}

class _RabPageState extends State<RabPage> {
  final formKey=GlobalKey<FormState>();
  final keyword=TextEditingController(), kodeKantor=TextEditingController(), namaKantor=TextEditingController();
  final kodeAo=TextEditingController(), namaAo=TextEditingController(), tahun=TextEditingController(), filterTahun=TextEditingController();
  final targetTabungan=TextEditingController(), targetKredit=TextEditingController(), targetDeposito=TextEditingController();
  List<RabModel> items=[]; int page=1,total=0,limit=10; int? filterBulan; int bulan=DateTime.now().month; String status='';
  bool loading=true, dialog=false, edit=false, canCreate=false,canUpdate=false,canDelete=false,canApprove=false; RabModel? selected; String? error;
  String get route=>widget.marketing?MenuNotifier.routeRabMarketing:MenuNotifier.routeRabKantor;
  String get title=>widget.marketing?'Target RAB Marketing':'Target RAB Kantor';

  @override void initState(){super.initState();_init();}
  Future<void> _init() async { final p=Pref(); final superAdmin=await p.getIsSuperAdmin(); final access=await p.getCoreAccessList(); CoreAccessModel? a;
    for(final x in access){if(x.matchesRoute(route)){a=x;break;}} canCreate=superAdmin||(a?.canCreate??false); canUpdate=superAdmin||(a?.canUpdate??false);
    canDelete=superAdmin||(a?.canDelete??false); canApprove=superAdmin||(a?.canApprove??false); await load(); }
  Future<void> load({int? toPage}) async {setState((){loading=true;error=null;if(toPage!=null)page=toPage;}); try{final r=await RabRepository.list(marketing:widget.marketing,
    keyword:keyword.text.trim(),bulan:filterBulan,tahun:int.tryParse(filterTahun.text),status:status,page:page,limit:limit); items=r.items;total=r.total;page=r.page;}catch(e){items=[];error=e.toString();}if(mounted)setState(()=>loading=false);}
  void clear(){selected=null;edit=false;kodeKantor.clear();namaKantor.clear();kodeAo.clear();namaAo.clear();bulan=DateTime.now().month;tahun.text=DateTime.now().year.toString();targetTabungan.text='0';targetKredit.text='0';targetDeposito.text='0';}
  void add(){clear();setState(()=>dialog=true);}
  Future<void> openEdit(RabModel row) async {DialogCustom().showLoading(context);try{final d=await RabRepository.detail(widget.marketing,row.id);if(mounted)Navigator.pop(context);selected=d;edit=true;
    kodeKantor.text=d.kodeKantor;namaKantor.text=d.namaKantor;kodeAo.text=d.kodeAo;namaAo.text=d.namaAo;bulan=d.bulan;tahun.text=d.tahun.toString();
    targetTabungan.text=d.targetTabungan.toString();targetKredit.text=_money(d.targetKredit);targetDeposito.text=_money(d.targetDeposito);setState(()=>dialog=true);
    }catch(e){if(mounted)Navigator.pop(context);if(mounted)informationDialog(context,'Warning',e.toString());}}
  Future<void> save() async {if(!(formKey.currentState?.validate()??false))return;final body=<String,dynamic>{if(edit)'id':selected!.id,'kode_kantor':kodeKantor.text.trim(),
    'nama_kantor':namaKantor.text.trim(),'bulan':bulan,'tahun':int.parse(tahun.text),'target_tabungan':int.parse(targetTabungan.text),
    'target_kredit':double.parse(cleanCurrencyInput(targetKredit.text)),'target_deposito':double.parse(cleanCurrencyInput(targetDeposito.text))};
    if(widget.marketing){body['kode_ao']=kodeAo.text.trim();body['nama_ao']=namaAo.text.trim();}DialogCustom().showLoading(context);try{await RabRepository.save(widget.marketing,edit,body);
    if(mounted)Navigator.pop(context);if(mounted)informationDialog(context,'Informasi','$title berhasil disimpan.');setState(()=>dialog=false);await load();}catch(e){if(mounted)Navigator.pop(context);if(mounted)informationDialog(context,'Warning',e.toString());}}
  Future<void> remove(RabModel row) async {DialogCustom().showLoading(context);try{await RabRepository.delete(widget.marketing,row.id);if(mounted)Navigator.pop(context);await load();}catch(e){if(mounted)Navigator.pop(context);if(mounted)informationDialog(context,'Warning',e.toString());}}
  Future<void> authorize(RabModel row,String action) async {final note=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text('${action=='APPROVE'?'Approve':'Reject'} $title'),content:TextField(controller:note,maxLines:3,decoration:dec('Keterangan')),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Batal')),ElevatedButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Proses'))]));if(ok!=true)return;
    DialogCustom().showLoading(context);try{await RabRepository.authorize(widget.marketing,row.id,action,note.text.trim());if(mounted)Navigator.pop(context);await load();}catch(e){if(mounted)Navigator.pop(context);if(mounted)informationDialog(context,'Warning',e.toString());}finally{note.dispose();}}
  Future<void> pickOffice() async {final v=await showDialog<KantorModel>(context:context,builder:(_)=>const _OfficePicker());if(v!=null){kodeKantor.text=v.kodeKantor;namaKantor.text=v.namaKantor;setState((){});}}
  Future<void> pickAo() async {final v=await showDialog<AoModel>(context:context,builder:(_)=>const _AoPicker());if(v!=null){kodeAo.text=v.kodeAo;namaAo.text=v.namaAo;if(v.kodeKantor.isNotEmpty){kodeKantor.text=v.kodeKantor;final offices=await HrisRepository.listKantor();for(final o in offices){if(o.kodeKantor==v.kodeKantor){namaKantor.text=o.namaKantor;break;}}}setState((){});}}

  @override Widget build(BuildContext context)=>SafeArea(child:Scaffold(body:Stack(children:[Column(children:[Container(padding:const EdgeInsets.all(20),color:Colors.white,child:Wrap(spacing:10,runSpacing:10,crossAxisAlignment:WrapCrossAlignment.center,children:[SizedBox(width:220,child:Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))),SizedBox(width:230,child:TextField(controller:keyword,onSubmitted:(_)=>load(toPage:1),decoration:dec('Kode / Nama'))),SizedBox(width:140,child:DropdownButtonFormField<int?>(value:filterBulan,decoration:dec('Bulan'),items:[const DropdownMenuItem(value:null,child:Text('Semua')),...List.generate(12,(i)=>DropdownMenuItem(value:i+1,child:Text('${i+1}')))],onChanged:(v)=>setState(()=>filterBulan=v))),SizedBox(width:130,child:TextField(controller:filterTahun,keyboardType:TextInputType.number,inputFormatters:[FilteringTextInputFormatter.digitsOnly],decoration:dec('Tahun'))),SizedBox(width:150,child:DropdownButtonFormField<String>(value:status,decoration:dec('Status'),items:const [DropdownMenuItem(value:'',child:Text('Semua')),DropdownMenuItem(value:'D',child:Text('Draft')),DropdownMenuItem(value:'A',child:Text('Approved')),DropdownMenuItem(value:'R',child:Text('Rejected'))],onChanged:(v)=>setState(()=>status=v??''))),ElevatedButton(onPressed:()=>load(toPage:1),child:const Text('Cari')),if(canCreate)ElevatedButton.icon(onPressed:add,icon:const Icon(Icons.add),label:const Text('Tambah'))])),Expanded(child:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Text(error!)):_table()),_pager()]),if(dialog)_form()])),);

  Widget _table(){if(items.isEmpty)return Center(child:Text('Data $title tidak ditemukan.'));return SingleChildScrollView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.all(16),child:DataTable(columnSpacing:24,columns:[const DataColumn(label:Text('Kantor')),if(widget.marketing)const DataColumn(label:Text('AO')),const DataColumn(label:Text('Periode')),const DataColumn(label:Text('Target Tab.')),const DataColumn(label:Text('Realisasi Tab.')),const DataColumn(label:Text('Target Kredit')),const DataColumn(label:Text('Realisasi Kredit')),const DataColumn(label:Text('Target Deposito')),const DataColumn(label:Text('Realisasi Deposito')),const DataColumn(label:Text('Status')),const DataColumn(label:SizedBox(width:190,child:Text('Aksi')))],rows:items.map((r)=>DataRow(cells:[DataCell(Text('${r.kodeKantor} - ${r.namaKantor}')),if(widget.marketing)DataCell(Text('${r.kodeAo} - ${r.namaAo}')),DataCell(Text('${r.bulan.toString().padLeft(2,'0')}-${r.tahun}')),DataCell(Text('${r.targetTabungan}')),DataCell(Text('${r.realisasiTabungan}')),DataCell(Text(_money(r.targetKredit))),DataCell(Text(_money(r.realisasiKredit))),DataCell(Text(_money(r.targetDeposito))),DataCell(Text(_money(r.realisasiDeposito))),DataCell(Text(r.displayStatus)),DataCell(SizedBox(width:190,child:Row(mainAxisSize:MainAxisSize.min,children:[if(canUpdate)IconButton(tooltip:'Edit',onPressed:()=>openEdit(r),icon:const Icon(Icons.edit)),if(canApprove&&r.status=='D')IconButton(tooltip:'Approve',onPressed:()=>authorize(r,'APPROVE'),icon:const Icon(Icons.check,color:Colors.green)),if(canApprove&&r.status=='D')IconButton(tooltip:'Reject',onPressed:()=>authorize(r,'REJECT'),icon:const Icon(Icons.close,color:Colors.orange)),if(canDelete)IconButton(tooltip:'Hapus',onPressed:()=>remove(r),icon:const Icon(Icons.delete,color:Colors.red))])))] )).toList()));}
  Widget _pager()=>Padding(padding:const EdgeInsets.all(12),child:Row(mainAxisAlignment:MainAxisAlignment.end,children:[Text('Total $total  •  Halaman $page'),IconButton(onPressed:page>1?()=>load(toPage:page-1):null,icon:const Icon(Icons.chevron_left)),IconButton(onPressed:page*limit<total?()=>load(toPage:page+1):null,icon:const Icon(Icons.chevron_right))]));
  Widget _form()=>Positioned.fill(child:Container(color:Colors.black26,alignment:Alignment.centerRight,child:Container(width:620,color:Colors.white,height:double.infinity,child:Form(key:formKey,child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Expanded(child:Text('${edit?'Edit':'Tambah'} $title',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))),IconButton(onPressed:()=>setState(()=>dialog=false),icon:const Icon(Icons.close))]),const SizedBox(height:20),if(!widget.marketing)field(kodeKantor,'Kode Kantor *',readOnly:true,onTap:pickOffice),if(widget.marketing)field(kodeAo,'Kode AO *',readOnly:true,onTap:pickAo),if(widget.marketing)field(namaAo,'Nama AO *',readOnly:true),field(namaKantor,'Nama Kantor *',readOnly:true,onTap:widget.marketing?pickOffice:null),DropdownButtonFormField<int>(value:bulan,decoration:dec('Bulan *'),items:List.generate(12,(i)=>DropdownMenuItem(value:i+1,child:Text('${i+1}'))),onChanged:(v)=>setState(()=>bulan=v??1)),const SizedBox(height:12),field(tahun,'Tahun *',digits:true,validator:(v){final n=int.tryParse(v??'');return n==null||n<2024?'Tahun minimal 2024':null;}),field(targetTabungan,'Target Jumlah Rekening Tabungan',digits:true,validator:nonNegativeInt),field(targetKredit,'Target Total Plafond Kredit',currency:true,validator:nonNegativeMoney),field(targetDeposito,'Target Total Nominal Deposito',currency:true,validator:nonNegativeMoney),const SizedBox(height:12),ElevatedButton(onPressed:save,style:ElevatedButton.styleFrom(backgroundColor:colorPrimary,minimumSize:const Size(100,50)),child:const Text('Simpan',style:TextStyle(color:Colors.white)))]))))));
  Widget field(TextEditingController c,String label,{bool readOnly=false,bool digits=false,bool currency=false,VoidCallback? onTap,String? Function(String?)? validator})=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextFormField(controller:c,readOnly:readOnly,onTap:onTap,keyboardType:(digits||currency)?TextInputType.number:null,inputFormatters:digits?[FilteringTextInputFormatter.digitsOnly]:currency?[CurrencyInputFormatter()]:null,validator:validator??(label.contains('*')?(v)=>(v??'').trim().isEmpty?'Wajib diisi':null:null),decoration:dec(label).copyWith(suffixIcon:onTap!=null?IconButton(onPressed:onTap,icon:const Icon(Icons.search)):null)));
  String? nonNegativeInt(String? v){final n=int.tryParse(v??'');return n==null||n<0?'Nilai tidak boleh negatif':null;} String? nonNegativeMoney(String? v){final n=double.tryParse(cleanCurrencyInput(v??''));return n==null||n<0?'Nilai tidak boleh negatif':null;}
  @override void dispose(){for(final c in [keyword,kodeKantor,namaKantor,kodeAo,namaAo,tahun,filterTahun,targetTabungan,targetKredit,targetDeposito]){c.dispose();}super.dispose();}
}

class _OfficePicker extends StatefulWidget{const _OfficePicker();@override State<_OfficePicker> createState()=>_OfficePickerState();}
class _OfficePickerState extends State<_OfficePicker>{final search=TextEditingController();late Future<List<KantorModel>> future=HrisRepository.listKantor();@override Widget build(BuildContext c)=>_picker<KantorModel>(c,'Pilih Kantor',search,future,(q)=>setState(()=>future=HrisRepository.listKantor()),(x)=>'${x.kodeKantor} - ${x.namaKantor}',(x)=>Navigator.pop(c,x),filter:(x,q)=>x.kodeKantor.toLowerCase().contains(q)||x.namaKantor.toLowerCase().contains(q));@override void dispose(){search.dispose();super.dispose();}}
class _AoPicker extends StatefulWidget{const _AoPicker();@override State<_AoPicker> createState()=>_AoPickerState();}
class _AoPickerState extends State<_AoPicker>{final search=TextEditingController();late Future<List<AoModel>> future=AoRepository.list(limit:100);@override Widget build(BuildContext c)=>_picker<AoModel>(c,'Pilih Account Officer',search,future,(q)=>setState(()=>future=AoRepository.list(keyword:q,limit:100)),(x)=>'${x.kodeAo} - ${x.namaAo}',(x)=>Navigator.pop(c,x));@override void dispose(){search.dispose();super.dispose();}}
Widget _picker<T>(BuildContext context,String title,TextEditingController search,Future<List<T>> future,void Function(String) find,String Function(T) label,void Function(T) pick,{bool Function(T,String)? filter})=>AlertDialog(title:Text(title),content:SizedBox(width:650,height:480,child:Column(children:[TextField(controller:search,onSubmitted:find,decoration:dec('Cari').copyWith(suffixIcon:IconButton(onPressed:()=>find(search.text),icon:const Icon(Icons.search)))),const SizedBox(height:10),Expanded(child:FutureBuilder<List<T>>(future:future,builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());final q=search.text.trim().toLowerCase();final rows=(s.data??[]).where((x)=>filter==null||q.isEmpty||filter(x,q)).toList();return ListView.separated(itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(_,i)=>ListTile(title:Text(label(rows[i])),onTap:()=>pick(rows[i])));} ))])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Tutup'))]);
InputDecoration dec(String label)=>InputDecoration(labelText:label,filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(8)));
String _money(num value)=>value.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'),(_)=>'.');
