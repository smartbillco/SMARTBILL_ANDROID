class Receipt {
  final String uuid;
  final String tipoDocumentoId;
  final String tipoDocumentoNombre;
  final String fechaEmision;
  final String serie;
  final String folio;
  final Emisor emisor;
  final Receptor receptor;
  final Totales totales;
  final List<Validacion> validaciones;
  final List<dynamic> eventos;

  Receipt({
    required this.uuid,
    required this.tipoDocumentoId,
    required this.tipoDocumentoNombre,
    required this.fechaEmision,
    required this.serie,
    required this.folio,
    required this.emisor,
    required this.receptor,
    required this.totales,
    required this.validaciones,
    required this.eventos,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      uuid: json['uuid'],
      tipoDocumentoId: json['tipoDocumentoId'],
      tipoDocumentoNombre: json['tipoDocumentoNombre'],
      fechaEmision: json['fechaEmision'],
      serie: json['serie'],
      folio: json['folio'],
      emisor: Emisor.fromJson(json['emisor']),
      receptor: Receptor.fromJson(json['receptor']),
      totales: Totales.fromJson(json['totales']),
      validaciones: (json['validaciones'] as List)
          .map((e) => Validacion.fromJson(e))
          .toList(),
      eventos: json['eventos'] ?? [],
    );
  }
}

class Validacion {
  final String nombre;
  final String status;
  final String mensajeError;
  final bool valida;

  Validacion({
    required this.nombre,
    required this.status,
    required this.mensajeError,
    required this.valida,
  });

  factory Validacion.fromJson(Map<String, dynamic> json) {
    return Validacion(
      nombre: json['nombre'],
      status: json['status'],
      mensajeError: json['mensajeError'],
      valida: json['valida'],
    );
  }
}

class Receptor {
  final String nombre;
  final String numeroDoc;
  final String? tipoDoc;

  Receptor({
    required this.nombre,
    required this.numeroDoc,
    this.tipoDoc,
  });

  factory Receptor.fromJson(Map<String, dynamic> json) {
    return Receptor(
      nombre: json['nombre'],
      numeroDoc: json['numeroDoc'],
      tipoDoc: json['tipoDoc'],
    );
  }
}


class Emisor {
  final String nombre;
  final String numeroDoc;
  final String? tipoDoc;

  Emisor({
    required this.nombre,
    required this.numeroDoc,
    this.tipoDoc,
  });

  factory Emisor.fromJson(Map<String, dynamic> json) {
    return Emisor(
      nombre: json['nombre'],
      numeroDoc: json['numeroDoc'],
      tipoDoc: json['tipoDoc'],
    );
  }
}

class Totales {
  final double total;
  final double? iva;

  Totales({
    required this.total,
    this.iva,
  });

  factory Totales.fromJson(Map<String, dynamic> json) {
    return Totales(
      total: (json['total'] as num).toDouble(),
      iva: json['iva'] != null ? (json['iva'] as num).toDouble() : null,
    );
  }
}