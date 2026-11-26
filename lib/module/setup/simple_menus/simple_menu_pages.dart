import 'package:flutter/services.dart';
import 'package:cms_core/repository/lending_setup_repository.dart';
import 'package:cms_core/models/index.dart';
import 'package:flutter/material.dart';
import 'package:cms_core/models/banking_setup_models.dart';
import 'package:cms_core/module/shared/banking_widgets.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/repository/SetupRepository.dart';

enum SimpleMenu { hours, holidays, collateral }

const _days = {'1':'Senin','2':'Selasa','3':'Rabu','4':'Kamis','5':'Jumat','6':'Sabtu','7':'Minggu'};
const _groups = {'KENDARAAN':'Kendaraan','TANAH':'Tanah','TANAH_BANGUNAN':'Tanah & Bangunan','DEPOSITO':'Deposito','LAINNYA':'Lainnya'};
const _bases = {'NILAI_PASAR':'Nilai Pasar','NILAI_LIKUIDASI':'Nilai Likuidasi','NILAI_TAKSASI':'Nilai Taksasi'};
String _route(SimpleMenu menu) => menu == SimpleMenu.hours ? '/setup/jam-operasional' : menu == SimpleMenu.holidays ? '/setup/hari-libur' : '/master/agunan';
String _title(SimpleMenu menu) => menu == SimpleMenu.hours ? 'Jam Operasional' : menu == SimpleMenu.holidays ? 'Hari Libur' : 'Master Agunan';
String _key(SimpleMenu menu) => menu == SimpleMenu.hours ? 'hari' : menu == SimpleMenu.holidays ? 'id' : 'kode_agunan';
String _text(dynamic value) => value?.toString() ?? '';

Future<dynamic> _request(SimpleMenu menu, String action, Map<String,dynamic> body) async {
  final response = await Setuprepository.fetch('$url${_route(menu)}/$action', body);
  if (response is! Map || response['code']?.toString() != '000') {
    throw Exception(response is Map ? response['message'] ?? 'Permintaan gagal' : 'Respons tidak valid');
  }
  return response['data'];
}

class SimpleMenuPage extends StatefulWidget {
  final SimpleMenu menu;
  const SimpleMenuPage({super.key, required this.menu});
  @override
  State<SimpleMenuPage> createState() => menu == SimpleMenu.hours ? _OperatingHoursState() : _SimpleMenuState();
}
class _SimpleMenuState extends BankingListState<Map<String,dynamic>,SimpleMenuPage> {
  int _year = DateTime.now().year;
  @override
  String get title => _title(widget.menu);
  @override
  String get route => _route(widget.menu);
  @override
  Map<String,String> get searchChoices => {'keyword': widget.menu == SimpleMenu.hours ? 'Hari' : widget.menu == SimpleMenu.holidays ? 'Tanggal / keterangan' : 'Kode / nama'};
  @override
  List<Widget> buildFilters() => widget.menu == SimpleMenu.holidays ? [
    OutlinedButton.icon(icon: const Icon(Icons.chevron_left), label: const Text('Tahun sebelumnya'), onPressed: actionBusy ? null : () {setState(() => _year--);reload(resetPage:true);}),
    Text('Tahun $_year'),
    OutlinedButton.icon(icon: const Icon(Icons.chevron_right), label: const Text('Tahun berikutnya'), onPressed: actionBusy ? null : () {setState(() => _year++);reload(resetPage:true);}),
  ] : widget.menu == SimpleMenu.hours ? [const Text('Semua jam dalam WIB. Pengaturan belum membatasi transaksi.')] : [];
  @override
  Future<BankingPage<Map<String,dynamic>>> fetchPage() async {
    final data = await _request(widget.menu,'list',{'keyword':keyword.text.trim(),'page':page,'limit':limit,if(widget.menu == SimpleMenu.holidays)'tahun':'$_year'});
    if (data is! Map || data['data'] is! List) throw Exception('Format daftar tidak valid');
    return BankingPage(items:(data['data'] as List).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList(),total:(data['total'] as num?)?.toInt() ?? 0,page:page,limit:limit);
  }
  @override
  Future<void> addRecord() => _edit();
  Future<void> _edit([Map<String,dynamic>? row,bool readOnly=false]) async {
    Map<String,dynamic>? detail;
    if(row != null) {
      final data = await _request(widget.menu,'detail',{_key(widget.menu):_text(row[_key(widget.menu)]),if(widget.menu==SimpleMenu.holidays)'tahun':_year});
      if(data is! Map) throw Exception('Detail tidak ditemukan');
      detail=Map<String,dynamic>.from(data);
      if(widget.menu==SimpleMenu.collateral){final setup=await LendingSetupRepository.detailAgunan(_text(detail['kode_agunan']));detail['nama_agunan']=setup.keterangan;}
    }
    if(!mounted)return;
    final saved = await showEditor(_SimpleForm(menu:widget.menu,original:detail,readOnly:readOnly||(widget.menu==SimpleMenu.holidays&&detail!=null&&detail['editable']!=true)));
    if(saved == true && mounted) await reload(resetPage:true);
  }
  Future<void> _delete(Map<String,dynamic> row) async {
    if(!await confirmDelete(_text(row[widget.menu == SimpleMenu.hours ? 'nama_hari' : _key(widget.menu)])) || !mounted)return;
    await _request(widget.menu,'delete',{_key(widget.menu):_text(row[_key(widget.menu)]),if(widget.menu==SimpleMenu.holidays)'tahun':_year});
    if(mounted)await reload(resetPage:true);
  }
  @override
  Widget buildTable(List<Map<String,dynamic>> rows) {
    final hours=widget.menu==SimpleMenu.hours, holidays=widget.menu==SimpleMenu.holidays;
    return bankingTable([
      if(hours)...['Hari','Libur','Jam Buka (WIB)','Jam Tutup (WIB)','Nonaktif Deposito','Nonaktif Pinjaman']
      else if(holidays)...['Tanggal','Keterangan','Jenis','Aktif']
      else ...['Kode','Nama','Kelompok','Bobot PPAP (%)','Nilai hitung PPAP dari','Maksimal dapat digunakan (%)','Nilai hitung digunakan dari'], 'Aksi',
    ],rows.map((row)=>DataRow(cells:[
      if(hours)...[
        DataCell(Text(_text(row['nama_hari']))),DataCell(Text(row['libur']==true?'Ya':'Tidak')),
        DataCell(Text(row['libur']==true?'-':_text(row['jam_buka']))),DataCell(Text(row['libur']==true?'-':_text(row['jam_tutup']))),
        DataCell(Text(row['nonaktif_deposito']==true?'Ya':'Tidak')),DataCell(Text(row['nonaktif_pinjaman']==true?'Ya':'Tidak')),
      ] else if(holidays)...[DataCell(Text(_text(row['tanggal']))),DataCell(Text(_text(row['keterangan']))),DataCell(Text(_text(row['jenis']).replaceAll('_',' '))),DataCell(Text(row['is_active']==true?'Ya':'Tidak'))]
      else ...[
        DataCell(Text(_text(row['kode_agunan']))),DataCell(Text(_text(row['nama_agunan']))),DataCell(Text(_groups[row['kelompok_agunan']]??_text(row['kelompok_agunan']))),
        DataCell(Text('${_text(row['bobot_ppap'])}%')),DataCell(Text(_bases[row['nilai_hitung_ppap']]??_text(row['nilai_hitung_ppap']))),
        DataCell(Text('${_text(row['maksimal_digunakan'])}%')),DataCell(Text(_bases[row['nilai_hitung_digunakan']]??_text(row['nilai_hitung_digunakan']))),
      ],
      DataCell(BankingActions(showEdit:access.update&&(!holidays||row['editable']==true),showDelete:access.delete&&(!holidays||row['editable']==true),
        onView:()=>perform(()=>_edit(row,true)),onEdit:access.update&&(!holidays||row['editable']==true)?()=>perform(()=>_edit(row)):null,
        onDelete:access.delete&&(!holidays||row['editable']==true)?()=>perform(()=>_delete(row)):null)),
    ])).toList());
  }
}

class _SimpleForm extends StatefulWidget {
  final SimpleMenu menu;
  final Map<String,dynamic>? original;
  final bool readOnly;
  const _SimpleForm({required this.menu,required this.original,required this.readOnly});
  @override
  State<_SimpleForm> createState()=>_SimpleFormState();
}
class _SimpleFormState extends State<_SimpleForm> {
  final _form=GlobalKey<FormState>();
  final _fields=<String,TextEditingController>{};
  bool _active=true;
  bool _busy=false,_holiday=false,_noDeposit=false,_noLoan=false;
  String _day='1',_group='KENDARAAN',_ppapBase='NILAI_PASAR',_usageBase='NILAI_PASAR';
  String? _error;
  bool get _locked=>widget.readOnly||_busy;
  TextEditingController f(String key)=>_fields[key]!;
  @override
  void initState(){
    super.initState();
    for(final key in ['tanggal','keterangan','jam_buka','jam_tutup','kode_agunan','nama_agunan','bobot_ppap','maksimal_digunakan']){
      _fields[key]=TextEditingController(text:_text(widget.original?[key]));
    }
    final row=widget.original;
    _active=row?['is_active']!=false;
    if(row!=null){
      _day=_text(row['hari']).isEmpty?'1':_text(row['hari']);
      _holiday=row['libur']==true;_noDeposit=row['nonaktif_deposito']==true;_noLoan=row['nonaktif_pinjaman']==true;
      _group=_groups.containsKey(row['kelompok_agunan'])?row['kelompok_agunan']:'KENDARAAN';
      _ppapBase=_bases.containsKey(row['nilai_hitung_ppap'])?row['nilai_hitung_ppap']:'NILAI_PASAR';
      _usageBase=_bases.containsKey(row['nilai_hitung_digunakan'])?row['nilai_hitung_digunakan']:'NILAI_PASAR';
    }else{f('jam_buka').text='08:00';f('jam_tutup').text='16:30';f('bobot_ppap').text='0';f('maksimal_digunakan').text='0';}
  }
  @override
  void dispose(){for(final field in _fields.values){field.dispose();}super.dispose();}
  Future<void> _browseAgunan() async {
    final chosen=await showDialog<AgunanSetupModel>(context:context,builder:(_)=>BankingLookupDialog<AgunanSetupModel>(
      title:'Pilih Kode Agunan',
      load:(keyword,page)async{final rows=await LendingSetupRepository.listAgunan(keyword:keyword,page:page,limit:20);return BankingPage(items:rows,total:(page-1)*20+rows.length+(rows.length==20?1:0),page:page,limit:20);},
      label:(v)=>v.kodeAgunan,subtitle:(v)=>v.keterangan));
    if(chosen==null||!mounted)return;
    setState(()=>_busy=true);
    try{final detail=await LendingSetupRepository.detailAgunan(chosen.kodeAgunan);if(mounted)setState((){f('kode_agunan').text=detail.kodeAgunan;f('nama_agunan').text=detail.keterangan;_error=null;});}
    catch(e){if(mounted)setState(()=>_error=e.toString());}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _date() async {
    final today = _todayWib();
    final selected = DateTime.tryParse(f('tanggal').text);
    final initial = selected == null || selected.isBefore(today) ? today : selected;
    final value=await showDatePicker(context:context,initialDate:initial,firstDate:today,lastDate:DateTime(2200));
    if(!mounted||value==null)return;
    setState(()=>f('tanggal').text='${value.year}-${value.month.toString().padLeft(2,'0')}-${value.day.toString().padLeft(2,'0')}');
  }
  Future<void> _time(String key) async {
    final parts=f(key).text.split(':');
    final value=await showTimePicker(context:context,initialTime:TimeOfDay(hour:int.tryParse(parts.first)??8,minute:parts.length>1?int.tryParse(parts[1])??0:0),
      builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(alwaysUse24HourFormat:true),child:child!));
    if(!mounted||value==null)return;
    setState(()=>f(key).text='${value.hour.toString().padLeft(2,'0')}:${value.minute.toString().padLeft(2,'0')}');
  }
  String? _percent(String? input){
    final text=(input??'').trim().replaceAll(',','.');final number=double.tryParse(text);
    return !RegExp(r'^\d+([.]\d{1,2})?$').hasMatch(text)||number==null||!number.isFinite||number<0||number>100?'Isi 0–100, maksimal 2 desimal':null;
  }
  Future<void> _save() async {
    if(_locked||!(_form.currentState?.validate()??false))return;
    if(widget.menu==SimpleMenu.holidays){
      final date=DateTime.tryParse(f('tanggal').text);
      if(date==null||date.isBefore(_todayWib())){setState(()=>_error='Tanggal hari libur tidak boleh sebelum hari ini (WIB)');return;}
    }
    final Map<String,dynamic> body;
    if(widget.menu==SimpleMenu.hours){
      if(!_holiday && f('jam_tutup').text.compareTo(f('jam_buka').text)<=0){setState(()=>_error='Jam tutup harus setelah jam buka');return;}
      body={'hari':_day,'libur':_holiday,'jam_buka':f('jam_buka').text,'jam_tutup':f('jam_tutup').text,'nonaktif_deposito':_noDeposit,'nonaktif_pinjaman':_noLoan};
    }else if(widget.menu==SimpleMenu.holidays){body={if(widget.original!=null)'id':widget.original!['id'],'tanggal':f('tanggal').text,'keterangan':f('keterangan').text.trim(),'is_active':_active};}
    else {body={'kode_agunan':f('kode_agunan').text.trim(),'nama_agunan':f('nama_agunan').text.trim(),'kelompok_agunan':_group,'bobot_ppap':double.parse(f('bobot_ppap').text.replaceAll(',','.')),'nilai_hitung_ppap':_ppapBase,'maksimal_digunakan':double.parse(f('maksimal_digunakan').text.replaceAll(',','.')),'nilai_hitung_digunakan':_usageBase};}
    setState((){_busy=true;_error=null;});
    try{await _request(widget.menu,widget.original==null?'create':'update',body);if(mounted)Navigator.of(context).pop(true);}
    catch(e){if(mounted)setState(()=>_error=e.toString());}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Widget _input(String label,String key,{int? max,bool fixed=false})=>bankingField(label,f(key),readOnly:_locked||fixed,required:true,
    validator:(text)=>(text??'').trim().isEmpty?'Wajib diisi':max!=null&&(text??'').runes.length>max?'Maksimal $max karakter':null);
  @override
  Widget build(BuildContext context)=>BankingFormDialog(title:'${widget.readOnly?'Detail':widget.original==null?'Tambah':'Edit'} ${_title(widget.menu)}',formKey:_form,onSave:_save,busy:_busy,readOnly:widget.readOnly,error:_error,fields:[
    if(widget.menu==SimpleMenu.hours)...[
      bankingDropdown('Hari',_day,_days,_locked||widget.original!=null?null:(v)=>setState(()=>_day=v!)),
      CheckboxListTile(contentPadding:EdgeInsets.zero,title:const Text('Libur'),value:_holiday,onChanged:_locked?null:(v)=>setState(()=>_holiday=v??false)),
      if(!_holiday)...[
        bankingField('Jam Buka (WIB)',f('jam_buka'),readOnly:true,required:true,search:_locked?null:()=>_time('jam_buka')),
        bankingField('Jam Tutup (WIB)',f('jam_tutup'),readOnly:true,required:true,search:_locked?null:()=>_time('jam_tutup')),
      ]else ...[
        CheckboxListTile(contentPadding:EdgeInsets.zero,title:const Text('Nonaktifkan pembukaan deposito pada hari ini'),value:_noDeposit,onChanged:_locked?null:(v)=>setState(()=>_noDeposit=v??false)),
        CheckboxListTile(contentPadding:EdgeInsets.zero,title:const Text('Nonaktifkan permohonan pinjaman pada hari ini'),value:_noLoan,onChanged:_locked?null:(v)=>setState(()=>_noLoan=v??false)),
      ],
      const Text('Pengaturan disimpan saja; belum diterapkan sebagai pembatasan transaksi.'),
    ]else if(widget.menu==SimpleMenu.holidays)...[
      bankingField('Tanggal',f('tanggal'),readOnly:true,required:true,search:_locked?null:_date),
      _input('Keterangan','keterangan',max:250),
      Text(widget.original==null?'Libur khusus untuk BPR Anda':_text(widget.original!['jenis']).replaceAll('_',' ')),
      CheckboxListTile(title:const Text('Aktif'),value:_active,onChanged:_locked?null:(v)=>setState(()=>_active=v??false)),
    ]else ...[
      bankingDropdown('Kelompok Agunan',_group,_groups,_locked?null:(v)=>setState(()=>_group=v!)),
      bankingField('Kode Agunan',f('kode_agunan'),readOnly:true,required:true,search:_locked||widget.original!=null?null:_browseAgunan),
      _input('Nama Agunan','nama_agunan',max:150,fixed:true),
      bankingField('Bobot PPAP (%)',f('bobot_ppap'),readOnly:_locked,required:true,keyboard:const TextInputType.numberWithOptions(decimal:true),formatters:[_AgunanPercentageFormatter()],validator:_percent),
      bankingDropdown('Nilai hitung PPAP dari',_ppapBase,_bases,_locked?null:(v)=>setState(()=>_ppapBase=v!)),
      bankingField('Maksimal dapat digunakan (%)',f('maksimal_digunakan'),readOnly:_locked,required:true,keyboard:const TextInputType.numberWithOptions(decimal:true),formatters:[_AgunanPercentageFormatter()],validator:_percent),
      bankingDropdown('Nilai hitung digunakan dari',_usageBase,_bases,_locked?null:(v)=>setState(()=>_usageBase=v!)),
    ],
  ]);
}

DateTime _todayWib() {
 final now=DateTime.now().toUtc().add(const Duration(hours:7));
 return DateTime(now.year,now.month,now.day);
}

class _OperatingHoursState extends State<SimpleMenuPage> {
 final List<Map<String,dynamic>> _rows=[];
 bool _loading=true,_saving=false;
 BankingPermissions _access=const BankingPermissions();
 String? _error;
 @override
 void initState(){super.initState();_load();}
 Future<void> _load() async {
  setState((){_loading=true;_error=null;});
  try{
   final access=await BankingPermissions.load('/setup/jam-operasional');
   final data=await _request(SimpleMenu.hours,'list',{'page':1,'limit':100});
   if(data is! Map || data['data'] is! List)throw Exception('Format daftar tidak valid');
   final saved=<String,Map<String,dynamic>>{};
   for(final row in data['data'] as List){if(row is Map)saved[_text(row['hari'])]=Map<String,dynamic>.from(row);}
   if(!mounted)return;
   setState((){
    _access=access;_rows.clear();
    for(final day in _days.keys){if(saved[day]!=null)_rows.add(saved[day]!);}
   });
  }catch(e){if(mounted)setState(()=>_error=e.toString());}
  finally{if(mounted)setState(()=>_loading=false);}
 }
 Future<void> _pick(Map<String,dynamic> row,String field)async{
  if(_saving||!_access.update)return;
  final parts=_text(row[field]).split(':');
  final hour=int.tryParse(parts.first)??8;
  final minute=parts.length>1?(int.tryParse(parts[1])??0):0;
  final value=await showTimePicker(context:context,initialTime:TimeOfDay(hour:hour.clamp(0,23).toInt(),minute:minute.clamp(0,59).toInt()),builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(alwaysUse24HourFormat:true),child:child!));
  if(!mounted||value==null)return;
  setState(()=>row[field]='${value.hour.toString().padLeft(2,'0')}:${value.minute.toString().padLeft(2,'0')}');
 }
 Future<void> _save()async{
  if(_saving||!_access.update)return;
  final items=<Map<String,dynamic>>[];
  for(final row in _rows){
   final holiday=row['libur']==true;
   final open=_text(row['jam_buka']),close=_text(row['jam_tutup']);
   if(!holiday && (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(open)||!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(close)||close.compareTo(open)<=0)){
    setState(()=>_error='${row['nama_hari']}: jam tutup harus setelah jam buka.');return;
   }
   items.add({'hari':row['hari'],'libur':holiday,'jam_buka':holiday?'':open,'jam_tutup':holiday?'':close,'nonaktif_deposito':row['nonaktif_deposito']==true,'nonaktif_pinjaman':row['nonaktif_pinjaman']==true});
  }
  setState((){_saving=true;_error=null;});
  try{await _request(SimpleMenu.hours,'update',{'days':items});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Jam operasional berhasil disimpan')));}
  catch(e){if(mounted)setState(()=>_error=e.toString());}
  finally{if(mounted)setState(()=>_saving=false);}
 }
 Widget _timeCell(Map<String,dynamic> row,String field)=>SizedBox(width:300,child:OutlinedButton.icon(
  onPressed:_saving||!_access.update?null:()=>_pick(row,field),icon:const Icon(Icons.access_time),label:Padding(padding:const EdgeInsets.all(16),child:Text(_text(row[field]).isEmpty?'Pilih jam':_text(row[field])))));
 Widget _flag(Map<String,dynamic> row,String field,String label)=>SizedBox(width:300,child:CheckboxListTile(contentPadding:EdgeInsets.zero,title:Text(label),value:row[field]==true,onChanged:_saving||!_access.update?null:(v)=>setState(()=>row[field]=v??false)));
 @override
 Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Row(children:[const Expanded(child:Text('Setup Jam Operasional',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold))),
   if(_access.update)ElevatedButton.icon(onPressed:_loading||_saving||_rows.length!=7?null:_save,icon:const Icon(Icons.save),label:Text(_saving?'Menyimpan...':'Simpan'))]),
  const SizedBox(height:20),const Text('Semua jam menggunakan Waktu Indonesia Barat (WIB)'),const SizedBox(height:16),
  if(_error!=null)Padding(padding:const EdgeInsets.only(bottom:12),child:Text(_error!,style:const TextStyle(color:Colors.red))),
  if(_loading)const Center(child:CircularProgressIndicator())
  else if(_rows.isEmpty)OutlinedButton(onPressed:_load,child:const Text('Coba lagi'))
  else Expanded(child:SingleChildScrollView(child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
   dataRowMinHeight:72,dataRowMaxHeight:100,columns:const [DataColumn(label:Text('Hari')),DataColumn(label:Text('Libur')),DataColumn(label:Text('Jam Buka (WIB)')),DataColumn(label:Text('Jam Tutup (WIB)')),DataColumn(label:Text('Nonaktif Deposito')),DataColumn(label:Text('Nonaktif Pinjaman'))],
   rows:_rows.map((row)=>DataRow(cells:[
    DataCell(Text(_text(row['nama_hari']))),
    DataCell(Checkbox(value:row['libur']==true,onChanged:_saving||!_access.update?null:(v)=>setState((){row['libur']=v??false;if(v==false){if(_text(row['jam_buka']).isEmpty)row['jam_buka']='08:00';if(_text(row['jam_tutup']).isEmpty)row['jam_tutup']='16:30';}}))),
    DataCell(row['libur']==true?const Text('-'):_timeCell(row,'jam_buka')),
    DataCell(row['libur']==true?const Text('-'):_timeCell(row,'jam_tutup')),
    DataCell(_flag(row,'nonaktif_deposito','Nonaktif Deposito')),
    DataCell(_flag(row,'nonaktif_pinjaman','Nonaktif Pinjaman')),
   ])).toList())))),
  const SizedBox(height:12),const Text('Centang Libur jika kantor tidak beroperasi pada hari tersebut.'),
 ]));
}


// Reject invalid edits/pastes while preserving the previous text and selection.
// Empty text and a trailing separator are allowed while the user is editing.
class _AgunanPercentageFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d+(?:[.,]\d{0,2})?$').hasMatch(text)) return oldValue;
    final number = double.tryParse(text.replaceAll(',', '.'));
    if (number == null || !number.isFinite || number < 0 || number > 100) return oldValue;
    return newValue;
  }
}
