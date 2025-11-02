/// Tipos de formulação disponíveis para produtos agrícolas
enum FormulationType {
  cr('CR', 'Concentrado - Formulação concentrada para diluição'),
  wg('WG', 'Grânulos Dispersíveis em Água - Grânulos que se dispersam na água'),
  wp('WP', 'Pó Molhável - Pó que se mistura com água formando suspensão'),
  sc('SC', 'Suspensão Concentrada - Suspensão estável de partículas sólidas'),
  od('OD', 'Suspensão Óleo em Água - Suspensão de óleo em meio aquoso'),
  zc('ZC', 'Concentrado Zeta - Concentrado com propriedades especiais'),
  dc('DC', 'Concentrado Disperso - Concentrado que se dispersa facilmente'),
  ze('ZE', 'Emulsão Zeta - Emulsão com propriedades especiais'),
  cs('CS', 'Suspensão de Cápsulas - Cápsulas suspensas em líquido'),
  se('SE', 'Suspensão Emulsão - Combinação de suspensão e emulsão'),
  zw('ZW', 'Suspensão Zeta - Suspensão com propriedades especiais'),
  ad('AD', 'Adjuvante - Produto auxiliar para melhorar aplicação'),
  ec('EC', 'Concentrado Emulsionável - Concentrado que forma emulsão'),
  eg('EG', 'Gel Emulsionável - Gel que forma emulsão'),
  ep('EP', 'Pó Emulsionável - Pó que forma emulsão'),
  eo('EO', 'Óleo Emulsionável - Óleo que forma emulsão'),
  ew('EW', 'Emulsão Óleo em Água - Emulsão de óleo em água'),
  me('ME', 'Microemulsão - Emulsão com gotículas muito pequenas'),
  sg('SG', 'Grânulos Solúveis - Grânulos que se dissolvem na água'),
  sp('SP', 'Pó Solúvel - Pó que se dissolve na água'),
  sl('SL', 'Solução - Solução líquida pronta para uso'),
  ff('FF', 'Formulação Fluida - Formulação líquida especial');

  const FormulationType(this.code, this.description);
  
  final String code;
  final String description;
  
  @override
  String toString() => code;
}
