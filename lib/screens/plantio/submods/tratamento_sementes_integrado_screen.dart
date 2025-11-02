import 'package:flutter/material.dart';
import '../../../models/seed_calc_result.dart';
import 'tratamento_sementes/tratamento_sementes_screen.dart';

// Manter compatibilidade com o nome original
class TratamentoSementesIntegradoScreen extends TratamentoSementesScreen {
  const TratamentoSementesIntegradoScreen({
    Key? key,
    SeedCalcResult? resultadoCalculo,
    required double pesoBag,
    required int numeroBags,
    required double sementesPorBag,
    required double germinacao,
    required double vigor,
  }) : super(
          key: key,
          resultadoCalculo: resultadoCalculo,
          pesoBag: pesoBag,
          numeroBags: numeroBags,
          sementesPorBag: sementesPorBag,
          germinacao: germinacao,
          vigor: vigor,
        );
}