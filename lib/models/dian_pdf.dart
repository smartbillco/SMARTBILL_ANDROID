class DianPdf {
  final int pdfSize;
  final Bill bill;
  final String pdf;

  DianPdf({
    required this.pdfSize,
    required this.bill,
    required this.pdf,
  });

  factory DianPdf.fromJson(Map<String, dynamic> json) {
    return DianPdf(
      pdfSize: json['pdfSize'],
      bill: Bill.fromJson(json['factura']),
      pdf: json['pdf'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pdfSize': pdfSize,
      'factura': bill.toJson(),
      'pdf': pdf,
    };
  }
}

class Bill {
  final String cufe;
  final String numeroFactura;
  final String fechaEmision;
  final String moneda;
  final String nitEmisor;
  final String nombreEmisor;
  final String? direccionEmisor;
  final String nitReceptor;
  final String nombreReceptor;
  final String? direccionReceptor;
  final int subtotal;
  final int iva;
  final int total;
  final String estado;
  final String mensajeEstado;
  final List<dynamic> lineas;
  final String codigoRespuestaDian;
  final String mensajeRespuestaDian;

  Bill({
    required this.cufe,
    required this.numeroFactura,
    required this.fechaEmision,
    required this.moneda,
    required this.nitEmisor,
    required this.nombreEmisor,
    this.direccionEmisor,
    required this.nitReceptor,
    required this.nombreReceptor,
    this.direccionReceptor,
    required this.subtotal,
    required this.iva,
    required this.total,
    required this.estado,
    required this.mensajeEstado,
    required this.lineas,
    required this.codigoRespuestaDian,
    required this.mensajeRespuestaDian,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      cufe: json['cufe'],
      numeroFactura: json['numeroFactura'],
      fechaEmision: json['fechaEmision'],
      moneda: json['moneda'],
      nitEmisor: json['nitEmisor'],
      nombreEmisor: json['nombreEmisor'],
      direccionEmisor: json['direccionEmisor'],
      nitReceptor: json['nitReceptor'],
      nombreReceptor: json['nombreReceptor'],
      direccionReceptor: json['direccionReceptor'],
      subtotal: json['subtotal'],
      iva: json['iva'],
      total: json['total'],
      estado: json['estado'],
      mensajeEstado: json['mensajeEstado'],
      lineas: json['lineas'] ?? [],
      codigoRespuestaDian: json['codigoRespuestaDian'],
      mensajeRespuestaDian: json['mensajeRespuestaDian'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cufe': cufe,
      'numeroFactura': numeroFactura,
      'fechaEmision': fechaEmision,
      'moneda': moneda,
      'nitEmisor': nitEmisor,
      'nombreEmisor': nombreEmisor,
      'direccionEmisor': direccionEmisor,
      'nitReceptor': nitReceptor,
      'nombreReceptor': nombreReceptor,
      'direccionReceptor': direccionReceptor,
      'subtotal': subtotal,
      'iva': iva,
      'total': total,
      'estado': estado,
      'mensajeEstado': mensajeEstado,
      'lineas': lineas,
      'codigoRespuestaDian': codigoRespuestaDian,
      'mensajeRespuestaDian': mensajeRespuestaDian,
    };
  }
}