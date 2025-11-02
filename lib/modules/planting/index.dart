// Módulo de Plantio - FortSmart Agro
// 
// Este módulo gerencia todas as operações relacionadas ao plantio,
// incluindo tratamento de sementes, calibragem e controle de estande.

// Modelos de dados
export 'models/plantio_model.dart';
export 'models/calibragem_adubo_model.dart';
export 'models/calibragem_semente_model.dart';
export 'models/estande_model.dart';
export 'models/semente_hectare_model.dart';
export 'models/variedade_model.dart';

// Repositórios
export 'repositories/plantio_repository.dart';

// Serviços
export 'services/plantio_service.dart';
export 'services/calibragem_adubo_service.dart';
export 'services/calibragem_semente_service.dart';
export 'services/data_cache_service.dart';
export 'services/estande_service.dart';
export 'services/migracao_service.dart';
export 'services/semente_hectare_service.dart';
export 'services/variedade_service.dart';

// Telas
export 'screens/plantio_lista_screen.dart';
export 'screens/plantio_detalhes_screen.dart';

// Widgets
export 'widgets/plantio_form.dart';

// Tratamento de Sementes (Integrado)
export '../tratamento_sementes/screens/ts_main_screen.dart';
export '../tratamento_sementes/models/dose_ts_model.dart';
export '../tratamento_sementes/models/calculo_ts_model.dart';
export '../tratamento_sementes/models/resultado_ts_model.dart';
export '../tratamento_sementes/services/ts_calculator_service.dart';
export '../tratamento_sementes/services/ts_compatibility_service.dart';
