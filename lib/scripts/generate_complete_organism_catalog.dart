import 'dart:convert';
import 'dart:io';

void main() async {
  final catalog = generateCompleteCatalog();
  final jsonString = JsonEncoder.withIndent('  ').convert(catalog);
  
  final file = File('../../assets/data/organism_catalog_complete.json');
  await file.writeAsString(jsonString);
  print('✅ Catálogo completo gerado com sucesso!');
}

Map<String, dynamic> generateCompleteCatalog() {
  return {
    "version": "2.0",
    "last_updated": "2025-01-27",
    "cultures": {
      "soja": generateSojaData(),
      "milho": generateMilhoData(),
      "sorgo": generateSorgoData(),
      "algodao": generateAlgodaoData(),
      "feijao": generateFeijaoData(),
      "girassol": generateGirassolData(),
      "aveia": generateAveiaData(),
      "trigo": generateTrigoData(),
      "gergelim": generateGergelimData(),
    }
  };
}

Map<String, dynamic> generateSojaData() {
  return {
    "id": "1",
    "name": "Soja",
    "organisms": {
      "pests": [
        createPest("soja_pest_001", "Bicudo-da-soja", "Sternechus subsignatus", "1", "adultos/m²", 1, 3, 4, "Praga subterrânea que ataca raízes e nódulos", "armadilhas de solo"),
        createPest("soja_pest_002", "Tamanduá-da-soja", "Sternechus spp.", "1", "adultos/m²", 1, 2, 3, "Praga subterrânea similar ao bicudo", "escavação de raízes"),
        createPest("soja_pest_003", "Percevejo-marrom", "Euschistus heros", "1", "unidades/ponto", 1, 3, 4, "Danos críticos em R5-R6", "pano-de-batida"),
        createPest("soja_pest_004", "Percevejo-verde", "Nezara viridula", "1", "unidades/ponto", 2, 4, 5, "Suga nos grãos", "pano-de-batida"),
        createPest("soja_pest_005", "Percevejo-verde-pequeno", "Piezodorus guildinii", "1", "unidades/ponto", 1, 3, 4, "Períodos mais quentes", "pano-de-batida"),
        createPest("soja_pest_006", "Lagarta-da-soja", "Anticarsia gemmatalis", "1", "lagartas/m", 2, 5, 6, "Desfolha significativa", "contagem por metro"),
        createPest("soja_pest_007", "Lagarta-falsa-medideira", "Chrysodeixis includens", "1", "lagartas/m", 2, 4, 5, "Desfolha e danos em vagens", "contagem por metro"),
        createPest("soja_pest_008", "Lagarta-do-cartucho", "Spodoptera frugiperda", "1", "lagartas/m", 2, 4, 5, "Resistência em áreas Bt", "contagem por metro"),
        createPest("soja_pest_009", "Lagarta-helicoverpa", "Helicoverpa armigera", "1", "lagartas/m", 1, 3, 4, "Praga interna", "contagem por metro"),
        createPest("soja_pest_010", "Mosca-branca", "Bemisia tabaci", "1", "adultos/folha", 9, 19, 20, "Vetor de vírus", "contagem no terço médio"),
        createPest("soja_pest_011", "Vaquinha", "Diabrotica speciosa", "1", "adultos/m²", 2, 5, 6, "Danos em folhas e flores", "contagem por m²"),
        createPest("soja_pest_012", "Ácaro-rajado", "Tetranychus urticae", "1", "% folhas com colônias", 9, 24, 25, "Prolifera em clima seco", "visualização"),
        createPest("soja_pest_013", "Caramujo", "Achatina fulica", "1", "indivíduos/m²", 1, 3, 4, "Danos em plântulas", "contagem por m²"),
        createPest("soja_pest_014", "Torrãozinho", "Scaptocoris castanea", "1", "adultos/m²", 2, 5, 6, "Praga subterrânea que ataca raízes", "escavação de solo"),
      ],
      "diseases": [
        createDisease("soja_disease_001", "Ferrugem-asiática", "Phakopsora pachyrhizi", "1", "% folhas com pústulas", 3, 10, 10, "Alto potencial de perda", "visualização"),
        createDisease("soja_disease_002", "Mancha-alvo", "Corynespora cassiicola", "1", "% folhas com lesões", 2, 6, 6, "Favorecida por umidade", "visualização"),
        createDisease("soja_disease_003", "Oídio", "Microsphaera diffusa", "1", "% folha coberta", 3, 10, 10, "Clima seco e noites frias", "visualização"),
        createDisease("soja_disease_004", "Mofo-branco", "Sclerotinia sclerotiorum", "1", "apotecios/ponto", 1, 3, 4, "Alta umidade", "contagem por ponto"),
        createDisease("soja_disease_005", "Antracnose", "Colletotrichum truncatum", "1", "% vagens/hastes", 2, 5, 5, "Ataca vagens e caule", "visualização"),
        createDisease("soja_disease_006", "Cancro-da-haste", "Diaporthe phaseolorum f.sp. meridionalis", "1", "% plantas com cancro", 2, 5, 5, "Lesões no caule", "visualização"),
        createDisease("soja_disease_007", "Mancha-parda", "Septoria glycines", "1", "% folhas com manchas", 4, 9, 10, "Manchas coalescentes", "visualização"),
        createDisease("soja_disease_008", "Nematoide-de-cisto", "Heterodera glycines", "1", "cistos/100g solo", 10, 50, 100, "Reduz produtividade", "análise de solo"),
        createDisease("soja_disease_009", "Nematoide-de-galha", "Meloidogyne spp.", "1", "ovos/100g solo", 50, 200, 500, "Forma galhas nas raízes", "análise de solo"),
        createDisease("soja_disease_010", "Nematoide-de-lesão", "Pratylenchus brachyurus", "1", "indivíduos/100g solo", 100, 500, 1000, "Lesiona raízes", "análise de solo"),
      ]
    }
  };
}

Map<String, dynamic> generateMilhoData() {
  return {
    "id": "2",
    "name": "Milho",
    "organisms": {
      "pests": [
        createPest("milho_pest_001", "Lagarta-do-cartucho", "Spodoptera frugiperda", "2", "lagartas/m", 2, 4, 5, "Praga principal do milho", "contagem por metro"),
        createPest("milho_pest_002", "Lagarta-elasmo", "Elasmopalpus lignosellus", "2", "lagartas/m", 1, 3, 4, "Danos no colo da planta", "contagem por metro"),
        createPest("milho_pest_003", "Lagarta-rosca", "Agrotis ipsilon", "2", "lagartas/m", 1, 2, 3, "Corta plantas na base", "contagem por metro"),
        createPest("milho_pest_004", "Percevejo-barriga-verde", "Dichelops spp.", "2", "unidades/ponto", 1, 3, 4, "Danos em plântulas", "pano-de-batida"),
        createPest("milho_pest_005", "Cigarrinha-do-milho", "Dalbulus maidis", "2", "adultos/planta", 2, 5, 6, "Vetor de vírus", "contagem por planta"),
        createPest("milho_pest_006", "Pulgão-do-milho", "Rhopalosiphum maidis", "2", "adultos/planta", 5, 15, 20, "Vetor de vírus", "contagem por planta"),
        createPest("milho_pest_007", "Coró", "Phyllophaga spp.", "2", "larvas/m²", 1, 3, 4, "Danos em raízes", "escavação de solo"),
        createPest("milho_pest_008", "Broca-da-cana", "Diatraea saccharalis", "2", "lagartas/m", 1, 2, 3, "Danos internos no colmo", "contagem por metro"),
      ],
      "diseases": [
        createDisease("milho_disease_001", "Ferrugem-polissora", "Puccinia polysora", "2", "% folhas com pústulas", 3, 10, 10, "Pústulas poligonais", "visualização"),
        createDisease("milho_disease_002", "Ferrugem-comum", "Puccinia sorghi", "2", "% folhas com pústulas", 2, 8, 10, "Pústulas circulares", "visualização"),
        createDisease("milho_disease_003", "Mancha-branca", "Phaeosphaeria maydis", "2", "% folhas com lesões", 2, 6, 8, "Lesões elípticas", "visualização"),
        createDisease("milho_disease_004", "Mancha-de-diplodia", "Stenocarpella maydis", "2", "% plantas com podridão", 2, 5, 6, "Podridão do colmo", "visualização"),
        createDisease("milho_disease_005", "Mancha-de-cercospora", "Cercospora zeae-maydis", "2", "% folhas com lesões", 3, 8, 10, "Lesões alongadas", "visualização"),
        createDisease("milho_disease_006", "Enfezamento-vermelho", "Mollicutes", "2", "% plantas com sintomas", 2, 5, 6, "Vermelhidão das folhas", "visualização"),
        createDisease("milho_disease_007", "Enfezamento-pálido", "Mollicutes", "2", "% plantas com sintomas", 2, 5, 6, "Clorose das folhas", "visualização"),
        createDisease("milho_disease_008", "Podridão-de-colmo", "Fusarium spp., Colletotrichum graminicola", "2", "% plantas com podridão", 2, 5, 6, "Podridão interna", "visualização"),
      ]
    }
  };
}

Map<String, dynamic> generateSorgoData() {
  return {
    "id": "3",
    "name": "Sorgo",
    "organisms": {
      "pests": [
        createPest("sorgo_pest_001", "Pulgão-do-sorgo", "Melanaphis sacchari", "3", "adultos/planta", 5, 15, 20, "Vetor de vírus", "contagem por planta"),
        createPest("sorgo_pest_002", "Lagarta-do-cartucho", "Spodoptera frugiperda", "3", "lagartas/m", 2, 4, 5, "Danos em folhas", "contagem por metro"),
        createPest("sorgo_pest_003", "Percevejo-barriga-verde", "Dichelops spp.", "3", "unidades/ponto", 1, 3, 4, "Danos em plântulas", "pano-de-batida"),
        createPest("sorgo_pest_004", "Lagarta-das-panículas", "Helicoverpa zea", "3", "lagartas/panícula", 1, 2, 3, "Danos em grãos", "contagem por panícula"),
        createPest("sorgo_pest_005", "Mosca-do-sorgo", "Contarinia sorghicola", "3", "adultos/panícula", 2, 5, 6, "Danos em flores", "contagem por panícula"),
      ],
      "diseases": [
        createDisease("sorgo_disease_001", "Antracnose", "Colletotrichum sublineolum", "3", "% folhas com lesões", 2, 6, 8, "Lesões alongadas", "visualização"),
        createDisease("sorgo_disease_002", "Mancha-foliar-de-cercospora", "Cercospora sorghi", "3", "% folhas com lesões", 3, 8, 10, "Lesões circulares", "visualização"),
        createDisease("sorgo_disease_003", "Ferrugem-do-sorgo", "Puccinia purpurea", "3", "% folhas com pústulas", 2, 8, 10, "Pústulas marrons", "visualização"),
        createDisease("sorgo_disease_004", "Podridão-do-colmo", "Fusarium spp., Macrophomina phaseolina", "3", "% plantas com podridão", 2, 5, 6, "Podridão interna", "visualização"),
      ]
    }
  };
}

Map<String, dynamic> generateAlgodaoData() {
  return {
    "id": "4",
    "name": "Algodão",
    "organisms": {
      "pests": [
        createPest("algodao_pest_001", "Bicudo-do-algodoeiro", "Anthonomus grandis", "4", "adultos/m²", 1, 3, 4, "Praga principal do algodão", "armadilhas"),
        createPest("algodao_pest_002", "Lagarta-do-cartucho", "Spodoptera frugiperda", "4", "lagartas/m", 2, 4, 5, "Danos em folhas", "contagem por metro"),
        createPest("algodao_pest_003", "Lagarta-rosada", "Pectinophora gossypiella", "4", "lagartas/m", 1, 3, 4, "Danos em maçãs", "contagem por metro"),
        createPest("algodao_pest_004", "Ácaro-rajado", "Tetranychus urticae", "4", "% folhas com colônias", 9, 24, 25, "Prolifera em clima seco", "visualização"),
        createPest("algodao_pest_005", "Pulgão-do-algodoeiro", "Aphis gossypii", "4", "adultos/planta", 5, 15, 20, "Vetor de vírus", "contagem por planta"),
        createPest("algodao_pest_006", "Mosca-branca", "Bemisia tabaci", "4", "adultos/folha", 9, 19, 20, "Vetor de vírus", "contagem por folha"),
        createPest("algodao_pest_007", "Tripes", "Frankliniella schultzei", "4", "indivíduos/flor", 2, 5, 6, "Danos em flores", "contagem por flor"),
        createPest("algodao_pest_008", "Vaquinha", "Diabrotica speciosa", "4", "adultos/m²", 2, 5, 6, "Danos em folhas", "contagem por m²"),
      ],
      "diseases": [
        createDisease("algodao_disease_001", "Ramulária", "Ramularia areola", "4", "% folhas com lesões", 2, 6, 8, "Lesões angulares", "visualização"),
        createDisease("algodao_disease_002", "Mancha-angular", "Xanthomonas citri subsp. malvacearum", "4", "% folhas com lesões", 2, 6, 8, "Lesões bacterianas", "visualização"),
        createDisease("algodao_disease_003", "Murcha-de-fusário", "Fusarium oxysporum f.sp. vasinfectum", "4", "% plantas com murcha", 2, 5, 6, "Murcha vascular", "visualização"),
        createDisease("algodao_disease_004", "Verticiliose", "Verticillium dahliae", "4", "% plantas com murcha", 2, 5, 6, "Murcha vascular", "visualização"),
        createDisease("algodao_disease_005", "Podridão-de-esclerotinia", "Sclerotinia sclerotiorum", "4", "apotecios/ponto", 1, 3, 4, "Podridão de maçãs", "contagem por ponto"),
      ]
    }
  };
}

Map<String, dynamic> generateFeijaoData() {
  return {
    "id": "5",
    "name": "Feijão",
    "organisms": {
      "pests": [
        createPest("feijao_pest_001", "Mosca-branca", "Bemisia tabaci", "5", "adultos/folha", 9, 19, 20, "Vetor de vírus", "contagem por folha"),
        createPest("feijao_pest_002", "Pulgão-preto", "Aphis craccivora", "5", "adultos/planta", 5, 15, 20, "Vetor de vírus", "contagem por planta"),
        createPest("feijao_pest_003", "Cigarrinha-verde", "Empoasca kraemeri", "5", "adultos/planta", 2, 5, 6, "Queima das folhas", "contagem por planta"),
        createPest("feijao_pest_004", "Lagarta-helicoverpa", "Helicoverpa armigera", "5", "lagartas/m", 1, 3, 4, "Danos em vagens", "contagem por metro"),
        createPest("feijao_pest_005", "Lagarta-das-vagens", "Etiella zinckenella", "5", "lagartas/m", 1, 2, 3, "Danos em vagens", "contagem por metro"),
        createPest("feijao_pest_006", "Ácaro-rajado", "Tetranychus urticae", "5", "% folhas com colônias", 9, 24, 25, "Prolifera em clima seco", "visualização"),
      ],
      "diseases": [
        createDisease("feijao_disease_001", "Antracnose", "Colletotrichum lindemuthianum", "5", "% plantas com lesões", 2, 6, 8, "Lesões em folhas e vagens", "visualização"),
        createDisease("feijao_disease_002", "Míldio", "Peronospora phaseoli", "5", "% folhas com esporulação", 2, 5, 6, "Esporulação na face inferior", "visualização"),
        createDisease("feijao_disease_003", "Mancha-angular", "Phaeoisariopsis griseola", "5", "% folhas com lesões", 2, 6, 8, "Lesões angulares", "visualização"),
        createDisease("feijao_disease_004", "Ferrugem-do-feijoeiro", "Uromyces appendiculatus", "5", "% folhas com pústulas", 2, 8, 10, "Pústulas marrons", "visualização"),
        createDisease("feijao_disease_005", "Fusariose", "Fusarium oxysporum", "5", "% plantas com murcha", 2, 5, 6, "Murcha vascular", "visualização"),
        createDisease("feijao_disease_006", "Mofo-branco", "Sclerotinia sclerotiorum", "5", "apotecios/ponto", 1, 3, 4, "Podridão de vagens", "contagem por ponto"),
      ]
    }
  };
}

Map<String, dynamic> generateGirassolData() {
  return {
    "id": "6",
    "name": "Girassol",
    "organisms": {
      "pests": [
        createPest("girassol_pest_001", "Lagarta-da-coroa", "Agrotis ipsilon", "6", "lagartas/m", 1, 3, 4, "Corta plantas na base", "contagem por metro"),
        createPest("girassol_pest_002", "Lagarta-do-capítulo", "Helicoverpa armigera", "6", "lagartas/capítulo", 1, 2, 3, "Danos em grãos", "contagem por capítulo"),
        createPest("girassol_pest_003", "Percevejo-marrom", "Nezara viridula", "6", "unidades/ponto", 1, 3, 4, "Danos em grãos", "pano-de-batida"),
        createPest("girassol_pest_004", "Pulgão-preto", "Aphis fabae", "6", "adultos/planta", 5, 15, 20, "Vetor de vírus", "contagem por planta"),
      ],
      "diseases": [
        createDisease("girassol_disease_001", "Mofo-branco", "Sclerotinia sclerotiorum", "6", "apotecios/ponto", 1, 3, 4, "Podridão de capítulos", "contagem por ponto"),
        createDisease("girassol_disease_002", "Ferrugem-do-girassol", "Puccinia helianthi", "6", "% folhas com pústulas", 2, 8, 10, "Pústulas marrons", "visualização"),
        createDisease("girassol_disease_003", "Mancha-de-alternária", "Alternaria helianthi", "6", "% folhas com lesões", 2, 6, 8, "Lesões circulares", "visualização"),
        createDisease("girassol_disease_004", "Verticiliose", "Verticillium dahliae", "6", "% plantas com murcha", 2, 5, 6, "Murcha vascular", "visualização"),
        createDisease("girassol_disease_005", "Podridão-do-colo", "Phoma macdonaldii", "6", "% plantas com podridão", 2, 5, 6, "Podridão do colo", "visualização"),
      ]
    }
  };
}

Map<String, dynamic> generateAveiaData() {
  return {
    "id": "7",
    "name": "Aveia",
    "organisms": {
      "pests": [
        createPest("aveia_pest_001", "Pulgão-da-aveia", "Rhopalosiphum padi", "7", "adultos/planta", 5, 15, 20, "Vetor de vírus", "contagem por planta"),
        createPest("aveia_pest_002", "Lagarta-do-cartucho", "Spodoptera frugiperda", "7", "lagartas/m", 2, 4, 5, "Danos em folhas", "contagem por metro"),
        createPest("aveia_pest_003", "Gorgulho-do-colmo", "Sitodiplosis mosellana", "7", "adultos/m²", 2, 5, 6, "Danos em colmos", "contagem por m²"),
      ],
      "diseases": [
        createDisease("aveia_disease_001", "Ferrugem-da-aveia", "Puccinia coronata f.sp. avenae", "7", "% folhas com pústulas", 2, 8, 10, "Pústulas coroadas", "visualização"),
        createDisease("aveia_disease_002", "Mancha-de-pirenofora", "Pyrenophora avenae", "7", "% folhas com lesões", 2, 6, 8, "Lesões alongadas", "visualização"),
        createDisease("aveia_disease_003", "Oídio", "Blumeria graminis", "7", "% folha coberta", 3, 10, 10, "Micélio pulverulento", "visualização"),
        createDisease("aveia_disease_004", "Podridão-do-colmo", "Fusarium spp.", "7", "% plantas com podridão", 2, 5, 6, "Podridão interna", "visualização"),
      ]
    }
  };
}

Map<String, dynamic> generateTrigoData() {
  return {
    "id": "8",
    "name": "Trigo",
    "organisms": {
      "pests": [
        createPest("trigo_pest_001", "Pulgão-verde-dos-cereais", "Schizaphis graminum", "8", "adultos/planta", 5, 15, 20, "Vetor de vírus", "contagem por planta"),
        createPest("trigo_pest_002", "Pulgão-da-espiga", "Sitobion avenae", "8", "adultos/espiga", 3, 8, 10, "Danos em grãos", "contagem por espiga"),
        createPest("trigo_pest_003", "Lagarta-do-cartucho", "Spodoptera frugiperda", "8", "lagartas/m", 2, 4, 5, "Danos em folhas", "contagem por metro"),
        createPest("trigo_pest_004", "Gorgulho-do-colmo", "Sitodiplosis mosellana", "8", "adultos/m²", 2, 5, 6, "Danos em colmos", "contagem por m²"),
      ],
      "diseases": [
        createDisease("trigo_disease_001", "Ferrugem-da-folha", "Puccinia triticina", "8", "% folhas com pústulas", 2, 8, 10, "Pústulas pequenas", "visualização"),
        createDisease("trigo_disease_002", "Ferrugem-do-colmo", "Puccinia graminis f.sp. tritici", "8", "% plantas com pústulas", 2, 8, 10, "Pústulas alongadas", "visualização"),
        createDisease("trigo_disease_003", "Ferrugem-amarela", "Puccinia striiformis", "8", "% folhas com pústulas", 2, 8, 10, "Pústulas amarelas", "visualização"),
        createDisease("trigo_disease_004", "Oídio", "Blumeria graminis f.sp. tritici", "8", "% folha coberta", 3, 10, 10, "Micélio pulverulento", "visualização"),
        createDisease("trigo_disease_005", "Giberela", "Fusarium graminearum", "8", "% espigas com sintomas", 2, 5, 6, "Podridão de espigas", "visualização"),
        createDisease("trigo_disease_006", "Mancha-bronzeada", "Bipolaris sorokiniana", "8", "% folhas com lesões", 2, 6, 8, "Lesões elípticas", "visualização"),
        createDisease("trigo_disease_007", "Mancha-de-pirenofora", "Pyrenophora tritici-repentis", "8", "% folhas com lesões", 2, 6, 8, "Lesões alongadas", "visualização"),
      ]
    }
  };
}

Map<String, dynamic> generateGergelimData() {
  return {
    "id": "9",
    "name": "Gergelim",
    "organisms": {
      "pests": [
        createPest("gergelim_pest_001", "Lagarta-helicoverpa", "Helicoverpa armigera", "9", "lagartas/m", 1, 3, 4, "Danos em vagens", "contagem por metro"),
        createPest("gergelim_pest_002", "Lagarta-do-cartucho", "Spodoptera frugiperda", "9", "lagartas/m", 2, 4, 5, "Danos em folhas", "contagem por metro"),
        createPest("gergelim_pest_003", "Mosca-branca", "Bemisia tabaci", "9", "adultos/folha", 9, 19, 20, "Vetor de vírus", "contagem por folha"),
        createPest("gergelim_pest_004", "Tripes", "Frankliniella schultzei", "9", "indivíduos/flor", 2, 5, 6, "Danos em flores", "contagem por flor"),
      ],
      "diseases": [
        createDisease("gergelim_disease_001", "Murcha-de-fusário", "Fusarium oxysporum f.sp. sesami", "9", "% plantas com murcha", 2, 5, 6, "Murcha vascular", "visualização"),
        createDisease("gergelim_disease_002", "Mancha-de-alternária", "Alternaria sesami", "9", "% folhas com lesões", 2, 6, 8, "Lesões circulares", "visualização"),
        createDisease("gergelim_disease_003", "Cercosporiose", "Cercospora sesami", "9", "% folhas com lesões", 2, 6, 8, "Lesões alongadas", "visualização"),
        createDisease("gergelim_disease_004", "Oídio", "Oidium sesami", "9", "% folha coberta", 3, 10, 10, "Micélio pulverulento", "visualização"),
      ]
    }
  };
}

Map<String, dynamic> createPest(String id, String name, String scientificName, String cropId, String unit, int low, int medium, int high, String description, String monitoring) {
  return {
    "id": id,
    "name": name,
    "scientific_name": scientificName,
    "type": "pest",
    "crop_id": cropId,
    "crop_name": getCropName(cropId),
    "unit": unit,
    "low_limit": low,
    "medium_limit": medium,
    "high_limit": high,
    "description": description,
    "monitoring_method": monitoring
  };
}

Map<String, dynamic> createDisease(String id, String name, String scientificName, String cropId, String unit, int low, int medium, int high, String description, String monitoring) {
  return {
    "id": id,
    "name": name,
    "scientific_name": scientificName,
    "type": "disease",
    "crop_id": cropId,
    "crop_name": getCropName(cropId),
    "unit": unit,
    "low_limit": low,
    "medium_limit": medium,
    "high_limit": high,
    "description": description,
    "monitoring_method": monitoring
  };
}

String getCropName(String cropId) {
  switch (cropId) {
    case "1": return "Soja";
    case "2": return "Milho";
    case "3": return "Sorgo";
    case "4": return "Algodão";
    case "5": return "Feijão";
    case "6": return "Girassol";
    case "7": return "Aveia";
    case "8": return "Trigo";
    case "9": return "Gergelim";
    default: return "Cultura";
  }
}
