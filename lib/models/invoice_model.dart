import 'dart:convert';
import 'package:flutter/foundation.dart';

// Helper functions for safe parsing
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  if (value is int) return value == 1;
  return false;
}

// Background parsing method
Future<InvoiceData> parseInvoiceData(String jsonString) async {
  return compute(invoiceDataFromJson, jsonString);
}

InvoiceData invoiceDataFromJson(String str) {
  try {
    final json = jsonDecode(str);
    return InvoiceData.fromJson(json);
  } catch (e) {
    debugPrint('Error parsing invoice data: $e');
    throw FormatException('No se pudo parsear la factura: $e');
  }
}

String invoiceDataToJson(InvoiceData data) => json.encode(data.toJson());

class InvoiceData {
  final String razonSocialProveedor;
  final String direccionProveedor;
  final String fechaEmision;
  final String fechaVencimiento;
  final String moneda;
  final double totalGravado;
  final double totalInafecto;
  final double totalGeneral;
  final double totalIgv;
  final List<DetalleComprobanteBean> detalleComprobanteBean;
  final Metadatos metadatos;

  InvoiceData({
    required this.razonSocialProveedor,
    required this.direccionProveedor,
    required this.fechaEmision,
    required this.fechaVencimiento,
    required this.moneda,
    required this.totalGravado,
    required this.totalInafecto,
    required this.totalGeneral,
    required this.totalIgv,
    required this.detalleComprobanteBean,
    required this.metadatos,
  });

  factory InvoiceData.fromJson(Map<String, dynamic> json) {
    List<DetalleComprobanteBean> detalles = [];
    if (json["detalleComprobanteBean"] != null && json["detalleComprobanteBean"] is List) {
      detalles = (json["detalleComprobanteBean"] as List)
          .map((x) => x == null ? null : DetalleComprobanteBean.fromJson(x as Map<String, dynamic>))
          .where((item) => item != null)
          .cast<DetalleComprobanteBean>()
          .toList();
    }

    return InvoiceData(
      razonSocialProveedor: json["razonSocialProveedor"]?.toString() ?? "",
      direccionProveedor: json["direccionProveedor"]?.toString() ?? "",
      fechaEmision: json["fechaEmision"]?.toString() ?? "",
      fechaVencimiento: json["fechaVencimiento"]?.toString() ?? "",
      moneda: json["moneda"]?.toString() ?? "PEN",
      totalGravado: _parseDouble(json["totalGravado"]),
      totalInafecto: _parseDouble(json["totalInafecto"]),
      totalGeneral: _parseDouble(json["totalGeneral"]),
      totalIgv: _parseDouble(json["totalIgv"]),
      detalleComprobanteBean: detalles,
      metadatos: Metadatos.fromJson(json["metadatos"] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    "razonSocialProveedor": razonSocialProveedor,
    "direccionProveedor": direccionProveedor,
    "fechaEmision": fechaEmision,
    "fechaVencimiento": fechaVencimiento,
    "moneda": moneda,
    "totalGravado": totalGravado.toStringAsFixed(2),
    "totalInafecto": totalInafecto.toStringAsFixed(2),
    "totalGeneral": totalGeneral.toStringAsFixed(2),
    "totalIgv": totalIgv.toStringAsFixed(2),
    "detalleComprobanteBean": List<dynamic>.from(detalleComprobanteBean.map((x) => x.toJson())),
    "metadatos": metadatos.toJson(),
  };

  // Método para validar datos
  bool get isValid {
    return razonSocialProveedor.isNotEmpty &&
           metadatos.ruc.isNotEmpty &&
           detalleComprobanteBean.isNotEmpty;
  }

  // Método para obtener resumen
  Map<String, dynamic> getSummary() {
    return {
      'proveedor': razonSocialProveedor,
      'ruc': metadatos.ruc,
      'total': totalGeneral,
      'moneda': moneda,
      'fecha_emision': fechaEmision,
    };
  }
}

// Extensión para métodos adicionales
extension InvoiceDataExtension on InvoiceData {
  String get formattedTotal {
    return '${moneda == 'USD' ? '\$' : 'S/'} ${totalGeneral.toStringAsFixed(2)}';
  }
}

class DetalleComprobanteBean {
  final int item;
  final double cantidad;
  final String descripcion;
  final double valorUnitario;
  final double montoTotalSinIgv;
  final bool afectoIgv;

  DetalleComprobanteBean({
    required this.item,
    required this.cantidad,
    required this.descripcion,
    required this.valorUnitario,
    required this.montoTotalSinIgv,
    required this.afectoIgv,
  });

  factory DetalleComprobanteBean.fromJson(Map<String, dynamic> json) => DetalleComprobanteBean(
    item: _parseInt(json["item"]),
    cantidad: _parseDouble(json["cantidad"]),
    descripcion: json["descripcion"]?.toString() ?? "",
    valorUnitario: _parseDouble(json["valorUnitario"]),
    montoTotalSinIgv: _parseDouble(json["montoTotalSinIgv"]),
    afectoIgv: _parseBool(json["afectoIgv"]),
  );

  Map<String, dynamic> toJson() => {
    "item": item,
    "cantidad": cantidad.toString(),
    "descripcion": descripcion,
    "valorUnitario": valorUnitario.toStringAsFixed(10),
    "montoTotalSinIgv": montoTotalSinIgv.toStringAsFixed(2),
    "afectoIgv": afectoIgv,
  };
}

class Metadatos {
  final String ruc;
  final String tipoDocumento;
  final String serie;
  final String numero;

  Metadatos({
    required this.ruc,
    required this.tipoDocumento,
    required this.serie,
    required this.numero,
  });

  factory Metadatos.fromJson(Map<String, dynamic> json) => Metadatos(
    ruc: json["ruc"]?.toString() ?? "",
    tipoDocumento: json["tipoDocumento"]?.toString() ?? "",
    serie: json["serie"]?.toString() ?? "",
    numero: json["numero"]?.toString() ?? "",
  );

  Map<String, dynamic> toJson() => {
    "ruc": ruc,
    "tipoDocumento": tipoDocumento,
    "serie": serie,
    "numero": numero,
  };
}
