enum EstadoRegistro { exito, fracaso }

extension EstadoRegistroX on EstadoRegistro {
  int get value => this == EstadoRegistro.exito ? 1 : 0;
  static EstadoRegistro fromInt(int v) => v == 1 ? EstadoRegistro.exito : EstadoRegistro.fracaso;
}

class Registro {
  final String fecha; 
  final EstadoRegistro estado;

  const Registro({required this.fecha, required this.estado});

  Registro copyWith({String? fecha, EstadoRegistro? estado}) =>
      Registro(fecha: fecha ?? this.fecha, estado: estado ?? this.estado);
}

class ResumenMensual {
  final int exitos;
  final int fracasos;
  final int total;
  double get porcentajeExito => total == 0 ? 0 : exitos / total;

  const ResumenMensual({required this.exitos, required this.fracasos}) : total = exitos + fracasos;
}

class RachaInfo {
  final int actual; 
  final int mejorDelMes;
  final int mejorHistorica; 

  const RachaInfo({required this.actual, required this.mejorDelMes, required this.mejorHistorica});
}
