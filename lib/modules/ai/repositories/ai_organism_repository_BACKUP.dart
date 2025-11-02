import '../models/ai_organism_data.dart';
import '../../../utils/logger.dart';

/// Repositório para dados de organismos da IA
class AIOrganismRepository {
  static final List<AIOrganismData> _organisms = [];

  /// Inicializa o repositório com dados padrão
  Future<void> initialize() async {
    try {
      Logger.info('🔍 Inicializando repositório de organismos da IA');
      
      if (_organisms.isNotEmpty) {
        Logger.info('✅ Repositório já inicializado');
        return;
      }

      await _loadDefaultOrganisms();
      Logger.info('✅ Repositório inicializado com ${_organisms.length} organismos');

    } catch (e) {
      Logger.error('❌ Erro ao inicializar repositório: $e');
    }
  }

  /// Carrega organismos padrão
  Future<void> _loadDefaultOrganisms() async {
    // ===== ORGANISMOS ORIGINAIS =====
    
    // Pragas da Soja (Originais)
    _organisms.add(AIOrganismData(
      id: 1,
      name: 'Lagarta da Soja',
      scientificName: 'Anticarsia gemmatalis',
      type: 'pest',
      crops: ['Soja'],
      symptoms: [
        'Folhas com furos irregulares',
        'Desfolhamento das plantas',
        'Presença de lagartas verdes',
        'Redução no crescimento',
      ],
      managementStrategies: [
        'Monitoramento semanal',
        'Controle biológico com Bacillus thuringiensis',
        'Aplicação de inseticidas quando necessário',
        'Rotação de culturas',
      ],
      description: 'Lagarta que se alimenta das folhas da soja, causando desfolhamento.',
      imageUrl: 'assets/images/pests/lagarta_soja.jpg',
      severity: 0.8,
      keywords: ['lagarta', 'desfolhamento', 'soja', 'inseto'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    
    _organisms.add(AIOrganismData(
      id: 2,
      name: 'Percevejo Verde',
      scientificName: 'Nezara viridula',
      type: 'pest',
      crops: ['Soja', 'Milho', 'Algodão'],
      symptoms: [
        'Grãos chochos',
        'Manchas escuras nos grãos',
        'Redução na produtividade',
        'Presença de insetos verdes',
      ],
      managementStrategies: [
        'Controle químico com inseticidas',
        'Monitoramento de populações',
        'Aplicação no momento correto',
        'Uso de variedades resistentes',
      ],
      description: 'Percevejo que suga os grãos, causando perdas na produtividade.',
      imageUrl: 'assets/images/pests/percevejo_verde.jpg',
      severity: 0.7,
      keywords: ['percevejo', 'grãos', 'sucção', 'produtividade'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Doenças da Soja (Originais)
    _organisms.add(AIOrganismData(
      id: 3,
      name: 'Ferrugem Asiática',
      scientificName: 'Phakopsora pachyrhizi',
      type: 'disease',
      crops: ['Soja'],
      symptoms: [
        'Manchas marrom-avermelhadas nas folhas',
        'Pústulas na parte inferior das folhas',
        'Desfolhamento precoce',
        'Redução na produtividade',
      ],
      managementStrategies: [
        'Aplicação de fungicidas preventivos',
        'Uso de variedades resistentes',
        'Vazio sanitário',
        'Monitoramento climático',
      ],
      description: 'Doença fúngica que causa manchas nas folhas e reduz a produtividade.',
      imageUrl: 'assets/images/diseases/ferrugem_asiatica.jpg',
      severity: 0.9,
      keywords: ['ferrugem', 'fungo', 'manchas', 'desfolhamento'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Pragas do Milho (Originais)
    _organisms.add(AIOrganismData(
      id: 4,
      name: 'Lagarta do Cartucho',
      scientificName: 'Spodoptera frugiperda',
      type: 'pest',
      crops: ['Milho'],
      symptoms: [
        'Furos nas folhas',
        'Danos no cartucho',
        'Presença de lagartas',
        'Redução no desenvolvimento',
      ],
      managementStrategies: [
        'Controle biológico',
        'Aplicação de inseticidas',
        'Monitoramento de ovos',
        'Uso de variedades Bt',
      ],
      description: 'Lagarta que ataca o cartucho do milho, causando perdas significativas.',
      imageUrl: 'assets/images/pests/lagarta_cartucho.jpg',
      severity: 0.8,
      keywords: ['lagarta', 'cartucho', 'milho', 'folhas'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Doenças do Milho (Originais)
    _organisms.add(AIOrganismData(
      id: 5,
      name: 'Cercosporiose',
      scientificName: 'Cercospora zeae-maydis',
      type: 'disease',
      crops: ['Milho'],
      symptoms: [
        'Manchas alongadas nas folhas',
        'Lesões marrom-claras',
        'Secamento das folhas',
        'Redução na fotossíntese',
      ],
      managementStrategies: [
        'Aplicação de fungicidas',
        'Uso de variedades resistentes',
        'Rotação de culturas',
        'Eliminação de restos culturais',
      ],
      description: 'Doença fúngica que causa manchas nas folhas do milho.',
      imageUrl: 'assets/images/diseases/cercosporiose.jpg',
      severity: 0.6,
      keywords: ['cercosporiose', 'manchas', 'folhas', 'fungo'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // ===== NOVOS ORGANISMOS DA SOJA (DETALHADOS) =====
    
    // 6. Torraozinho (Percevejo-marrom) - Novo
    _organisms.add(AIOrganismData(
      id: 6,
      name: 'Torraozinho (Percevejo-marrom)',
      scientificName: 'Euschistus heros',
      type: 'pest',
      crops: ['Soja'],
      symptoms: [
        'Inseto mastigador que se alimenta de folhas',
        'Raspa o caule de plântulas causando tombamento',
        'Desfolha parcial em plantas adultas',
        'Redução da área fotossintética',
        'Morte de plântulas nos estágios V2 a V4',
        'Redução da população efetiva da lavoura',
      ],
      managementStrategies: [
        'Monitoramento: 2 percevejos/m² no R5–R6',
        'Controle químico: Neonicotinoides + Piretróides (IRAC 4A/3A)',
        'Controle biológico: Telenomus podisi (parasitóide de ovos)',
        'Manejo cultural: Dessecação antecipada, plantio no período ideal',
        'Aplicação no enchimento de grãos (fenologia crítica)',
      ],
      description: 'Principal praga da soja na fase reprodutiva. Pode comprometer o estande inicial pela morte de plântulas e reduzir o potencial produtivo. Em casos severos, perdas superiores a 20% podem ocorrer.',
      imageUrl: 'assets/images/pests/torraozinho.jpg',
      severity: 0.9,
      keywords: ['torraozinho', 'percevejo-marrom', 'euschistus heros', 'soja', 'reprodutivo', 'grãos'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 7. Caramujo - Novo
    _organisms.add(AIOrganismData(
      id: 7,
      name: 'Caramujo',
      scientificName: 'Achatina fulica e Deroceras spp.',
      type: 'pest',
      crops: ['Soja'],
      symptoms: [
        'Raspa folhas jovens',
        'Corta plântulas ao nível do solo',
        'Danos no estabelecimento inicial da cultura',
        'Presença de moluscos na área',
      ],
      managementStrategies: [
        'Monitoramento: Presença de mais de 1 caramujo/m²',
        'Controle químico: Iscas moluscicidas (Metalaldeído)',
        'Controle biológico: Patógenos naturais (Phasmarhabditis hermaphrodita)',
        'Manejo cultural: Evitar excesso de umidade, limpeza de áreas',
        'Aplicação da emergência ao V3 (fenologia crítica)',
      ],
      description: 'Problema crescente em áreas irrigadas. Prejuízo maior no estabelecimento inicial da cultura.',
      imageUrl: 'assets/images/pests/caramujo.jpg',
      severity: 0.6,
      keywords: ['caramujo', 'achatina fulica', 'deroceras', 'molusco', 'plântulas', 'irrigação'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 8. Vaquinha - Novo
    _organisms.add(AIOrganismData(
      id: 8,
      name: 'Vaquinha',
      scientificName: 'Diabrotica speciosa',
      type: 'pest',
      crops: ['Soja'],
      symptoms: [
        'Adultos mastigam folhas em formato rendilhado',
        'Larvas atacam raízes',
        'Reduz área fotossintética',
        'Causa tombamento de plantas',
        'Também transmite viroses em hortaliças',
      ],
      managementStrategies: [
        'Monitoramento: 20% das folhas atacadas',
        'Controle químico: Neonicotinoides via tratamento de sementes',
        'Controle biológico: Metarhizium anisopliae, Beauveria bassiana',
        'Manejo cultural: Rotação de culturas, plantio direto',
        'Aplicação da emergência até V6 (fenologia crítica)',
      ],
      description: 'Besouro que reduz área fotossintética e causa tombamento de plantas.',
      imageUrl: 'assets/images/pests/vaquinha.jpg',
      severity: 0.7,
      keywords: ['vaquinha', 'diabrotica speciosa', 'besouro', 'folhas rendilhadas', 'raízes'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 9. Mosca-branca - Novo
    _organisms.add(AIOrganismData(
      id: 9,
      name: 'Mosca-branca',
      scientificName: 'Bemisia tabaci',
      type: 'pest',
      crops: ['Soja'],
      symptoms: [
        'Sugamento de seiva',
        'Transmissão de viroses',
        'Produção de fumagina',
        'Redução de até 40% no rendimento',
        'Prejuízo indireto por viroses',
      ],
      managementStrategies: [
        'Monitoramento: 10–20 adultos por folha no terço superior',
        'Controle químico: Inseticidas reguladores de crescimento (IRAC 16, 23)',
        'Controle biológico: Encarsia formosa (parasitóide)',
        'Manejo cultural: Evitar sobreposição de culturas hospedeiras',
        'Aplicação do vegetativo até maturação (fenologia crítica)',
      ],
      description: 'Mosca sugadora favorecida por clima quente e seco. Redução de até 40% no rendimento.',
      imageUrl: 'assets/images/pests/mosca_branca.jpg',
      severity: 0.8,
      keywords: ['mosca-branca', 'bemisia tabaci', 'sugadora', 'viroses', 'fumagina', 'clima quente'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 10. Lagarta Spodoptera - Novo
    _organisms.add(AIOrganismData(
      id: 10,
      name: 'Lagarta Spodoptera',
      scientificName: 'Spodoptera frugiperda',
      type: 'pest',
      crops: ['Soja'],
      symptoms: [
        'Desfolha intensa',
        'Ataque a vagens e grãos em formação',
        'Presença de lagartas polífagas',
        'Danos severos se não controlada',
      ],
      managementStrategies: [
        'Monitoramento: 20 lagartas pequenas por metro de fileira',
        'Controle químico: Diamidas, Baculovírus específicos',
        'Controle biológico: Trichogramma pretiosum (parasitóide de ovos)',
        'Manejo cultural: Destruição de soqueira, controle de plantas voluntárias',
        'Aplicação V4–R6 (fenologia crítica)',
      ],
      description: 'Lagarta polífaga altamente resistente a vários inseticidas. Pode causar perdas superiores a 50% se não controlada.',
      imageUrl: 'assets/images/pests/lagarta_spodoptera.jpg',
      severity: 0.9,
      keywords: ['lagarta spodoptera', 'spodoptera frugiperda', 'desfolha', 'vagens', 'polífaga', 'resistente'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 11. Lagarta Helicoverpa - Novo
    _organisms.add(AIOrganismData(
      id: 11,
      name: 'Lagarta Helicoverpa',
      scientificName: 'Helicoverpa armigera',
      type: 'pest',
      crops: ['Soja'],
      symptoms: [
        'Perfura vagens',
        'Destrói grãos diretamente',
        'Ataque a flores',
        'Impacto na qualidade do grão',
      ],
      managementStrategies: [
        'Monitoramento: 2 lagartas/m² no reprodutivo',
        'Controle químico: Espinosinas, diamidas (IRAC 5, 28)',
        'Controle biológico: Helicoverpa armigera nucleopolyhedrovirus (HearNPV)',
        'Manejo cultural: Plantio no período recomendado, destruição de restos',
        'Aplicação floração e enchimento de grãos (fenologia crítica)',
      ],
      description: 'Praga quarentenária de alta importância econômica. Perdas de até 40%, impacto na qualidade do grão.',
      imageUrl: 'assets/images/pests/lagarta_helicoverpa.jpg',
      severity: 0.9,
      keywords: ['lagarta helicoverpa', 'helicoverpa armigera', 'vagens', 'grãos', 'quarentenária', 'qualidade'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 12. Mancha-alvo - Novo
    _organisms.add(AIOrganismData(
      id: 12,
      name: 'Mancha-alvo',
      scientificName: 'Corynespora cassiicola',
      type: 'disease',
      crops: ['Soja'],
      symptoms: [
        'Lesões arredondadas com halo amarelado',
        'Aspecto de "alvo" nas folhas',
        'Reduz área foliar',
        'Favorecida por alta umidade',
      ],
      managementStrategies: [
        'Controle químico: Fungicidas sítio-específicos (FRAC 7, 11)',
        'Controle biológico: Trichoderma spp.',
        'Manejo cultural: Uso de cultivares tolerantes',
        'Aplicação floração até enchimento de grãos (fenologia crítica)',
      ],
      description: 'Fungo que reduz área foliar e produtividade em até 30%. Favorecida por alta umidade.',
      imageUrl: 'assets/images/diseases/mancha_alvo.jpg',
      severity: 0.7,
      keywords: ['mancha-alvo', 'corynespora cassiicola', 'fungo', 'lesões', 'halo amarelado', 'umidade'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 13. Nematoide de galha - Novo
    _organisms.add(AIOrganismData(
      id: 13,
      name: 'Nematoide de galha',
      scientificName: 'Meloidogyne spp.',
      type: 'disease',
      crops: ['Soja'],
      symptoms: [
        'Formação de galhas nas raízes',
        'Plantas atrofiadas',
        'Redução de 10–80% da produtividade',
        'Praga de solo, difícil manejo',
      ],
      managementStrategies: [
        'Controle químico: Nematicidas biológicos e químicos',
        'Controle biológico: Bacillus firmus, Purpureocillium lilacinum',
        'Manejo cultural: Rotação com milho, braquiária',
        'Aplicação durante todo o ciclo (fenologia crítica)',
      ],
      description: 'Nematoide que forma galhas nas raízes. Redução de 10–80% da produtividade. Praga de solo, difícil manejo.',
      imageUrl: 'assets/images/diseases/nematoide_galha.jpg',
      severity: 0.8,
      keywords: ['nematoide galha', 'meloidogyne', 'galhas', 'raízes', 'solo', 'atrofia'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 14. Cisto nas raízes - Novo
    _organisms.add(AIOrganismData(
      id: 14,
      name: 'Cisto nas raízes',
      scientificName: 'Heterodera glycines',
      type: 'disease',
      crops: ['Soja'],
      symptoms: [
        'Cistos brancos/amarelados nas raízes',
        'Reduz vigor das plantas',
        'Até 70% de redução de rendimento',
        'Uma das doenças mais graves da soja no Brasil',
      ],
      managementStrategies: [
        'Controle químico: Nematicidas registrados',
        'Controle biológico: Fungos antagonistas',
        'Manejo cultural: Cultivares resistentes, rotação',
        'Aplicação durante todo o ciclo (fenologia crítica)',
      ],
      description: 'Nematoide específico da soja. Uma das doenças mais graves da soja no Brasil. Até 70% de redução de rendimento.',
      imageUrl: 'assets/images/diseases/cisto_raizes.jpg',
      severity: 0.9,
      keywords: ['cisto raízes', 'heterodera glycines', 'cistos', 'raízes', 'nematoide específico', 'grave'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 15. Deficiências de Nutrientes - Novo
    _organisms.add(AIOrganismData(
      id: 15,
      name: 'Deficiências de Nutrientes',
      scientificName: 'N, P, K, S, Zn, Mn, B',
      type: 'disease',
      crops: ['Soja'],
      symptoms: [
        'N: folhas cloróticas',
        'P: crescimento lento, coloração arroxeada',
        'K: necrose nas bordas',
        'S: clorose em folhas jovens',
        'Zn/Mn/B: distúrbios em flores e enchimento de grãos',
      ],
      managementStrategies: [
        'Controle químico: Fertilizantes e corretivos específicos',
        'Manejo cultural: Adubação equilibrada, análise de solo',
        'Diagnóstico preciso é essencial para diferenciar de doenças',
        'Aplicação do vegetativo à reprodução (fenologia crítica)',
      ],
      description: 'Desordem nutricional que reduz produtividade e qualidade. Diagnóstico preciso é essencial para diferenciar de doenças.',
      imageUrl: 'assets/images/diseases/deficiencias_nutrientes.jpg',
      severity: 0.6,
      keywords: ['deficiências', 'nutrientes', 'clorose', 'necrose', 'adubação', 'análise solo'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // ===== ORGANISMOS DO ALGODÃO =====
    
    // 16. Bicudo-do-algodoeiro
    _organisms.add(AIOrganismData(
      id: 16,
      name: 'Bicudo-do-algodoeiro',
      scientificName: 'Anthonomus grandis',
      type: 'pest',
      crops: ['Algodão'],
      symptoms: [
        'Botões florais perfurados',
        'Flores com pétalas danificadas',
        'Maçãs pequenas e deformadas',
        'Redução drástica da produção',
      ],
      managementStrategies: [
        'Monitoramento: 5% dos botões atacados ou 1 bicudo/10 plantas',
        'Controle químico: Malation, Fenitrotion, Carbaril',
        'Controle biológico: Fungos entomopatogênicos, Nematoides',
        'Manejo cultural: Destruição de restos culturais, vazio sanitário',
        'Aplicação floração até colheita (fenologia crítica)',
      ],
      description: 'Praga quarentenária que pode causar perdas de até 80% da produção em infestações severas. Exige controle rigoroso.',
      imageUrl: 'assets/images/pests/bicudo_algodao.jpg',
      severity: 0.9,
      keywords: ['bicudo', 'anthonomus grandis', 'algodão', 'botões', 'quarentenária', 'severa'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 17. Mosca-branca do Algodão
    _organisms.add(AIOrganismData(
      id: 17,
      name: 'Mosca-branca do Algodão',
      scientificName: 'Bemisia tabaci',
      type: 'pest',
      crops: ['Algodão'],
      symptoms: [
        'Folhas com manchas amarelas',
        'Redução do crescimento',
        'Transmissão de vírus',
        'Melada nas folhas',
      ],
      managementStrategies: [
        'Monitoramento: 5 moscas-brancas/folha ou 10% das plantas infestadas',
        'Controle químico: Imidacloprido, Tiametoxam, Acetamiprido',
        'Controle biológico: Encarsia formosa, Eretmocerus mundus',
        'Manejo cultural: Eliminação de plantas hospedeiras, controle de plantas daninhas',
        'Aplicação durante todo o ciclo (fenologia crítica)',
      ],
      description: 'Pode causar perdas de até 60% e transmitir doenças virais. Vetor importante de vírus.',
      imageUrl: 'assets/images/pests/mosca_branca_algodao.jpg',
      severity: 0.8,
      keywords: ['mosca-branca', 'bemisia tabaci', 'algodão', 'vírus', 'melada', 'vetor'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 18. Pulgão-do-algodão
    _organisms.add(AIOrganismData(
      id: 18,
      name: 'Pulgão-do-algodão',
      scientificName: 'Aphis gossypii',
      type: 'pest',
      crops: ['Algodão'],
      symptoms: [
        'Enrolamento das folhas',
        'Redução do crescimento',
        'Melada nas folhas',
        'Presença de formigas',
      ],
      managementStrategies: [
        'Monitoramento: 50 pulgões/folha ou 10% das plantas infestadas',
        'Controle químico: Imidacloprido, Tiametoxam, Acetamiprido',
        'Controle biológico: Joaninhas, Crisopídeos',
        'Manejo cultural: Resistência varietal, controle de plantas daninhas',
        'Aplicação durante todo o ciclo (fenologia crítica)',
      ],
      description: 'Pode causar perdas de até 40% na produtividade. Vetor de vírus e produtor de melada.',
      imageUrl: 'assets/images/pests/pulgao_algodao.jpg',
      severity: 0.7,
      keywords: ['pulgão', 'aphis gossypii', 'algodão', 'melada', 'vírus', 'formigas'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // ===== ORGANISMOS DO FEIJÃO =====
    
    // 19. Mosca-branca do Feijão
    _organisms.add(AIOrganismData(
      id: 19,
      name: 'Mosca-branca do Feijão',
      scientificName: 'Bemisia tabaci',
      type: 'pest',
      crops: ['Feijão'],
      symptoms: [
        'Folhas com manchas amarelas',
        'Redução do crescimento',
        'Transmissão de vírus',
        'Enrolamento das folhas',
      ],
      managementStrategies: [
        'Monitoramento: 5 moscas-brancas/folha ou 10% das plantas infestadas',
        'Controle químico: Imidacloprido, Tiametoxam, Acetamiprido',
        'Controle biológico: Encarsia formosa, Eretmocerus mundus',
        'Manejo cultural: Eliminação de plantas hospedeiras, controle de plantas daninhas',
        'Aplicação durante todo o ciclo (fenologia crítica)',
      ],
      description: 'Pode causar perdas de até 60% e transmitir doenças virais. Vetor importante de vírus.',
      imageUrl: 'assets/images/pests/mosca_branca_feijao.jpg',
      severity: 0.8,
      keywords: ['mosca-branca', 'bemisia tabaci', 'feijão', 'vírus', 'manchas amarelas'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 20. Lagarta-rosca do Feijão
    _organisms.add(AIOrganismData(
      id: 20,
      name: 'Lagarta-rosca do Feijão',
      scientificName: 'Agrotis ipsilon',
      type: 'pest',
      crops: ['Feijão'],
      symptoms: [
        'Corte de plântulas na base',
        'Plantas tombadas',
        'Redução do estande',
        'Danos em raízes',
      ],
      managementStrategies: [
        'Monitoramento: 5% das plantas cortadas',
        'Controle químico: Clorantraniliprole, Tiametoxam',
        'Controle biológico: Bacillus thuringiensis, Nematoides entomopatogênicos',
        'Manejo cultural: Preparo adequado do solo, eliminação de plantas hospedeiras',
        'Aplicação da emergência até V4 (fenologia crítica)',
      ],
      description: 'Pode causar perdas de até 30% devido à redução do estande. Mais comum em solos com resíduos vegetais.',
      imageUrl: 'assets/images/pests/lagarta_rosca_feijao.jpg',
      severity: 0.7,
      keywords: ['lagarta-rosca', 'agrotis ipsilon', 'feijão', 'corte', 'estande', 'plântulas'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 21. Lagarta falsa-medideira do Feijão
    _organisms.add(AIOrganismData(
      id: 21,
      name: 'Lagarta falsa-medideira do Feijão',
      scientificName: 'Chrysodeixis includens',
      type: 'pest',
      crops: ['Feijão'],
      symptoms: [
        'Desfolha irregular',
        'Perfurações nas folhas',
        'Redução da área fotossintética',
        'Presença de lagartas "esticadas"',
      ],
      managementStrategies: [
        'Monitoramento: 30% de desfolha no estágio vegetativo',
        'Controle químico: Clorantraniliprole, Espinetoram, Indoxacarbe',
        'Controle biológico: Bacillus thuringiensis, Vírus de poliedrose nuclear',
        'Manejo cultural: Monitoramento constante, controle biológico natural',
        'Aplicação do vegetativo até floração (fenologia crítica)',
      ],
      description: 'Pode causar perdas de até 50% devido à desfolha. Praga secundária que pode se tornar importante.',
      imageUrl: 'assets/images/pests/lagarta_falsa_medideira_feijao.jpg',
      severity: 0.6,
      keywords: ['lagarta falsa-medideira', 'chrysodeixis includens', 'feijão', 'desfolha', 'perfurações'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // ===== ORGANISMOS DO TRIGO =====
    
    // 22. Pulgão-do-trigo
    _organisms.add(AIOrganismData(
      id: 22,
      name: 'Pulgão-do-trigo',
      scientificName: 'Sitobion avenae',
      type: 'pest',
      crops: ['Trigo'],
      symptoms: [
        'Enrolamento das folhas',
        'Amarelecimento das folhas',
        'Redução do crescimento',
        'Transmissão de vírus',
        'Melada que favorece fungos',
      ],
      managementStrategies: [
        'Controle biológico com parasitoides',
        'Inseticidas sistêmicos',
        'Manejo de adubação nitrogenada',
        'Monitoramento regular',
        'Aplicação do perfilhamento até espigamento (fenologia crítica)',
      ],
      description: 'Praga-chave do trigo, pode causar perdas de até 30%. Temperaturas entre 15-25°C são favoráveis.',
      imageUrl: 'assets/images/pests/pulgao_trigo.jpg',
      severity: 0.8,
      keywords: ['pulgão', 'sitobion avenae', 'trigo', 'vírus', 'melada', 'nitrogênio'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 23. Pulgão-verme-do-colmo
    _organisms.add(AIOrganismData(
      id: 23,
      name: 'Pulgão-verme-do-colmo',
      scientificName: 'Rhopalosiphum padi',
      type: 'pest',
      crops: ['Trigo'],
      symptoms: [
        'Manchas avermelhadas nas folhas',
        'Enfraquecimento do colmo',
        'Redução do número de grãos',
        'Transmissão de vírus',
      ],
      managementStrategies: [
        'Inseticidas específicos',
        'Controle biológico',
        'Manejo nutricional',
        'Monitoramento semanal',
        'Aplicação do perfilhamento até enchimento de grãos (fenologia crítica)',
      ],
      description: 'Pode transmitir vírus importantes como o BYDV. Pode causar danos significativos na qualidade dos grãos.',
      imageUrl: 'assets/images/pests/pulgao_colmo.jpg',
      severity: 0.7,
      keywords: ['pulgão-verme', 'rhopalosiphum padi', 'trigo', 'colmo', 'BYDV', 'grãos'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // ===== ORGANISMOS DO SORGO =====
    
    // 24. Lagarta-do-cartucho do Sorgo
    _organisms.add(AIOrganismData(
      id: 24,
      name: 'Lagarta-do-cartucho do Sorgo',
      scientificName: 'Spodoptera frugiperda',
      type: 'pest',
      crops: ['Sorgo'],
      symptoms: [
        'Perfurações nas folhas',
        'Excrementos escuros no cartucho',
        'Destruição do ponto de crescimento',
        'Redução da produtividade',
      ],
      managementStrategies: [
        'Monitoramento: 10% das plantas com dano visível ou 1 lagarta/planta',
        'Controle químico: Clorantraniliprole, Espinetoram, Indoxacarbe',
        'Controle biológico: Trichogramma pretiosum, Vírus SfNPV',
        'Manejo cultural: Híbridos Bt, destruição de restos, refúgio',
        'Aplicação da emergência até pendoamento (fenologia crítica)',
      ],
      description: 'Redução de até 50% da produtividade, principalmente em infestações no início do ciclo. População resistente em áreas Bt mal manejadas.',
      imageUrl: 'assets/images/pests/lagarta_cartucho_sorgo.jpg',
      severity: 0.8,
      keywords: ['lagarta cartucho', 'spodoptera frugiperda', 'sorgo', 'Bt', 'resistente'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // ===== ORGANISMOS DO GIRASSOL =====
    
    // 25. Lagarta-do-capítulo do Girassol
    _organisms.add(AIOrganismData(
      id: 25,
      name: 'Lagarta-do-capítulo do Girassol',
      scientificName: 'Helicoverpa zea',
      type: 'pest',
      crops: ['Girassol'],
      symptoms: [
        'Furos nos aquênios',
        'Destruição do capítulo',
        'Presença de excrementos escuros',
        'Galerias nos aquênios',
        'Redução da qualidade dos grãos',
      ],
      managementStrategies: [
        'Monitoramento: 5-10% de capítulos atacados',
        'Controle químico: Clorantraniliprole, Flubendiamide, Metomil',
        'Controle biológico: Trichogramma pretiosum, Telenomus remus, Bacillus thuringiensis',
        'Manejo cultural: Rotação de culturas, destruição de restos culturais',
        'Aplicação da floração até formação de aquênios (fenologia crítica)',
      ],
      description: 'Praga importante que pode causar perdas significativas na qualidade e quantidade dos grãos de girassol.',
      imageUrl: 'assets/images/pests/lagarta_capitulo_girassol.jpg',
      severity: 0.8,
      keywords: ['lagarta capítulo', 'helicoverpa zea', 'girassol', 'aquênios', 'capítulo'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // ===== ORGANISMOS DA AVEIA =====
    
    // 26. Pulgão-da-aveia
    _organisms.add(AIOrganismData(
      id: 26,
      name: 'Pulgão-da-aveia',
      scientificName: 'Rhopalosiphum padi',
      type: 'pest',
      crops: ['Aveia'],
      symptoms: [
        'Enrolamento das folhas',
        'Amarelecimento das folhas',
        'Redução do crescimento',
        'Transmissão de vírus',
        'Melada nas folhas',
      ],
      managementStrategies: [
        'Monitoramento regular desde o início',
        'Controle químico: Inseticidas sistêmicos',
        'Controle biológico: Parasitoides naturais',
        'Manejo cultural: Plantio na época adequada, adubação equilibrada',
        'Aplicação do perfilhamento até espigamento (fenologia crítica)',
      ],
      description: 'Praga importante da aveia que pode causar perdas significativas na produtividade e qualidade dos grãos.',
      imageUrl: 'assets/images/pests/pulgao_aveia.jpg',
      severity: 0.7,
      keywords: ['pulgão', 'rhopalosiphum padi', 'aveia', 'vírus', 'melada'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // ===== ORGANISMOS DO GERGELIM =====
    
    // 27. Lagarta-do-gergelim
    _organisms.add(AIOrganismData(
      id: 27,
      name: 'Lagarta-do-gergelim',
      scientificName: 'Anticarsia gemmatalis',
      type: 'pest',
      crops: ['Gergelim'],
      symptoms: [
        'Desfolha das plantas',
        'Perfurações nas folhas',
        'Redução da área fotossintética',
        'Danos em flores e frutos',
      ],
      managementStrategies: [
        'Monitoramento constante',
        'Controle químico: Inseticidas específicos',
        'Controle biológico: Bacillus thuringiensis',
        'Manejo cultural: Rotação de culturas, eliminação de restos',
        'Aplicação durante todo o ciclo (fenologia crítica)',
      ],
      description: 'Praga importante do gergelim que pode causar perdas significativas na produtividade da cultura.',
      imageUrl: 'assets/images/pests/lagarta_gergelim.jpg',
      severity: 0.6,
      keywords: ['lagarta', 'anticarsia gemmatalis', 'gergelim', 'desfolha', 'flores'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  /// Obtém todos os organismos
  Future<List<AIOrganismData>> getAllOrganisms() async {
    await initialize();
    return List.from(_organisms);
  }

  /// Obtém organismos por cultura
  Future<List<AIOrganismData>> getOrganismsByCrop(String cropName) async {
    await initialize();
    
    return _organisms.where((organism) {
      return organism.crops.any((crop) => 
          crop.toLowerCase() == cropName.toLowerCase());
    }).toList();
  }

  /// Obtém organismos por tipo
  Future<List<AIOrganismData>> getOrganismsByType(String type) async {
    await initialize();
    
    return _organisms.where((organism) => 
        organism.type.toLowerCase() == type.toLowerCase()).toList();
  }

  /// Busca organismos por nome ou sintoma
  Future<List<AIOrganismData>> searchOrganisms(String query) async {
    await initialize();
    
    final normalizedQuery = query.toLowerCase();
    
    return _organisms.where((organism) {
      return organism.name.toLowerCase().contains(normalizedQuery) ||
             organism.scientificName.toLowerCase().contains(normalizedQuery) ||
             organism.symptoms.any((symptom) => 
                 symptom.toLowerCase().contains(normalizedQuery)) ||
             organism.keywords.any((keyword) => 
                 keyword.toLowerCase().contains(normalizedQuery));
    }).toList();
  }

  /// Obtém organismo por ID
  Future<AIOrganismData?> getOrganismById(int id) async {
    await initialize();
    
    try {
      return _organisms.firstWhere((organism) => organism.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Adiciona novo organismo
  Future<bool> addOrganism(AIOrganismData organism) async {
    try {
      await initialize();
      
      // Verificar se já existe
      final exists = _organisms.any((o) => o.id == organism.id);
      if (exists) {
        Logger.warning('⚠️ Organismo já existe: ${organism.name}');
        return false;
      }
      
      _organisms.add(organism);
      Logger.info('✅ Organismo adicionado: ${organism.name}');
      return true;

    } catch (e) {
      Logger.error('❌ Erro ao adicionar organismo: $e');
      return false;
    }
  }

  /// Atualiza organismo existente
  Future<bool> updateOrganism(AIOrganismData organism) async {
    try {
      await initialize();
      
      final index = _organisms.indexWhere((o) => o.id == organism.id);
      if (index == -1) {
        Logger.warning('⚠️ Organismo não encontrado: ${organism.name}');
        return false;
      }
      
      _organisms[index] = organism.copyWith(updatedAt: DateTime.now());
      Logger.info('✅ Organismo atualizado: ${organism.name}');
      return true;

    } catch (e) {
      Logger.error('❌ Erro ao atualizar organismo: $e');
      return false;
    }
  }

  /// Remove organismo
  Future<bool> removeOrganism(int id) async {
    try {
      await initialize();
      
      final index = _organisms.indexWhere((o) => o.id == id);
      if (index == -1) {
        Logger.warning('⚠️ Organismo não encontrado: $id');
        return false;
      }
      
      final organism = _organisms.removeAt(index);
      Logger.info('✅ Organismo removido: ${organism.name}');
      return true;

    } catch (e) {
      Logger.error('❌ Erro ao remover organismo: $e');
      return false;
    }
  }

  /// Obtém estatísticas do repositório
  Future<Map<String, dynamic>> getStats() async {
    await initialize();
    
    final pestCount = _organisms.where((o) => o.type == 'pest').length;
    final diseaseCount = _organisms.where((o) => o.type == 'disease').length;
    final crops = _organisms.expand((o) => o.crops).toSet();
    
    return {
      'totalOrganisms': _organisms.length,
      'pests': pestCount,
      'diseases': diseaseCount,
      'crops': crops.length,
      'cropList': crops.toList(),
      'averageSeverity': _organisms.map((o) => o.severity).reduce((a, b) => a + b) / _organisms.length,
    };
  }
}
