/// Unidades de dosagem disponíveis
enum DoseUnit {
  l('L', 'Litros'),
  lPer100l('L/100L', 'Litros por 100 Litros'),
  ml('mL', 'Mililitros'),
  g('g', 'Gramas'),
  gPer100l('g/100L', 'Gramas por 100 Litros'),
  kg('kg', 'Quilogramas'),
  kgPer100l('kg/100L', 'Quilogramas por 100 Litros'),
  mlPer100l('mL/100L', 'Mililitros por 100 Litros'),
  percentVv('%v/v', 'Percentual Volume/Volume');

  const DoseUnit(this.symbol, this.description);
  
  final String symbol;
  final String description;
  
  @override
  String toString() => symbol;
}
