import 'dart:math' as math;

class EscalaGrafico {
  final double maximo;
  final double intervalo;

  const EscalaGrafico._(this.maximo, this.intervalo);

  factory EscalaGrafico.para(
    double valorMaximo, {
    int divisiones = 4,
    double? tope,
    bool entero = false,
  }) {
    if (valorMaximo <= 0) {
      final base = tope ?? divisiones.toDouble();
      return EscalaGrafico._(base, base / divisiones);
    }
    final bruto = valorMaximo / divisiones;
    final potencia = math.pow(10, (math.log(bruto) / math.ln10).floor()).toDouble();
    double paso = potencia * 10;
    for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (m * potencia >= bruto) {
        paso = m * potencia;
        break;
      }
    }
    if (entero && paso < 1) paso = 1;
    if (entero) paso = paso.ceilToDouble();
    var maximo = paso * divisiones;
    if (tope != null && maximo > tope && valorMaximo <= tope) {
      maximo = tope;
      paso = tope / divisiones;
    }
    return EscalaGrafico._(maximo, paso);
  }
}
