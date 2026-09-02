import '../../domain/entities/registro.dart';

class RegistroModel extends Registro {
  const RegistroModel({required super.fecha, required super.estado});

  factory RegistroModel.fromMap(Map<String, dynamic> map) {
    return RegistroModel(
      fecha: map['fecha'] as String,
      estado: (map['estado'] as int) == 1 ? EstadoRegistro.exito : EstadoRegistro.fracaso,
    );
  }

  Map<String, dynamic> toMap() => {
        'fecha': fecha,
        'estado': estado.value,
      };

  factory RegistroModel.fromEntity(Registro e) => RegistroModel(fecha: e.fecha, estado: e.estado);
}
