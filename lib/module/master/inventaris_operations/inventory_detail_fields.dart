import 'package:flutter/material.dart';
import 'package:cms_core/module/shared/banking_widgets.dart';

const inventoryDetailLabels = <String, String>{
  'asset_group': 'Kelompok Aset',
  'asset_class': 'Group Aset',
  'asset_condition': 'Kondisi Aset',
  'asset_status': 'Status Aset',
  'asset_office': 'Kantor Aset',
  'asset_location': 'Lokasi Aset',
  'asset_address': 'Alamat Aset',
  'asset_purchase_date': 'Tanggal Beli',
  'last_revaluation_date': 'Tanggal Revaluasi Terakhir',
  'asset_purchase_price': 'Harga Beli',
  'asset_acquisition': 'Total Perolehan',
  'asset_monthly_depreciation': 'Nilai Susut per Bulan',
  'old_value': 'Nilai Buku Saat Ini',
  'asset_supplier': 'Supplier',
};

Map<String, String> inventoryDetailSnapshot(Map<String, dynamic> raw) {
  String text(String key) => raw[key]?.toString() ?? '';
  return {
    'last_revaluation_date': text('tanggal_revaluasi_terakhir'),
    'code': text('kode_inventaris'), 'name': text('nama_inventaris'),
    'asset_group': text('kelompok_aset_label').isEmpty ? text('kelompok_aset') : text('kelompok_aset_label'),
    'asset_class': text('group_aset'),
    'asset_condition': text('kondisi_aset_label').isEmpty ? text('kondisi_aset') : text('kondisi_aset_label'),
    'asset_status': text('status_aset_label').isEmpty ? text('status_aset') : text('status_aset_label'),
    'asset_office': [text('kode_kantor'), text('nama_kantor')].where((e) => e.isNotEmpty).join(' • '),
    'asset_location': text('lokasi_aset'), 'asset_address': text('alamat'),
    'asset_purchase_date': text('tanggal_beli'), 'asset_purchase_price': text('harga_beli'),
    'asset_acquisition': text('total_perolehan'),
    'asset_monthly_depreciation': text('nilai_susut_perbulan'),
    // Book value must come from the gateway, never from purchase price or estimated elapsed months.
    'old_value': text('nilai_buku'), 'asset_supplier': text('nama_mitra'),
  };
}

List<Widget> inventoryDetailFields(Map<String, TextEditingController> fields, {Set<String> exclude = const {}}) => [
  for (final entry in inventoryDetailLabels.entries)
    if (!exclude.contains(entry.key)) bankingField(entry.value, fields[entry.key]!, readOnly: true),
];
