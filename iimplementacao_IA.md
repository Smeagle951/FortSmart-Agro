Plano Completo de Treinamento de IA e Integração com Flutter
1. Objetivo

Treinar um modelo DistilBERT Multilingual para classificar sintomas de plantas em doenças.
Converter o modelo para TFLite.
Integrar o modelo TFLite em um aplicativo Flutter para inferência em dispositivos móveis (Android/iOS).


2. Requisitos

Para Treinamento:

Bibliotecas: transformers, pandas, scikit-learn, torch, onnx, onnxruntime, tf2onnx, tensorflow, numpy.
Hardware: GPU (opcional para treinamento), CPU para conversão.


Para Flutter:

Flutter SDK (versão estável, ex.: 3.24.x).
Pacote tflite_flutter para carregar e executar o modelo TFLite.
Pacote bert_tokenizer ou uma implementação customizada para tokenizar textos no Flutter.
Dispositivo/emulador Android/iOS para testes.


Dataset:

Arquivo .csv inicial fornecido (8 amostras).
Recomenda-se aumentar com dados reais ou sintéticos.




3. Passos do Treinamento
3.1. Preparação do Dataset

Dataset inicial:

Salvar o dataset fornecido como plant_diseases.csv:
csvtexto,label
texto,label
"folhas amareladas com pontas queimadas","Deficiência de Potássio"
"manchas circulares com halo amarelado nas folhas","Mancha-alvo"
"pústulas alaranjadas na face inferior das folhas","Ferrugem Asiática"
"folhas secas e caindo precocemente","Cercospora"
"manchas pequenas marrons com centro claro","Septoriose"
"manchas brancas com micélio na superfície","Oídio"
"lesões aquosas que se tornam marrons","Antracnose"
"folhas enroladas e cloróticas","Virose"
"folhas com margens necrosadas e crescimento reduzido","Deficiência de Magnésio"
"manchas púrpuras nas bordas das folhas mais velhas","Deficiência de Fósforo"
"folhas novas deformadas e cloróticas","Deficiência de Zinco"
"manchas pretas irregulares nos caules e folhas","Podridão de Esclerotinia"
"pontos escuros e dispersos nas folhas","Mancha Parda"
"pústulas marrons no verso das folhas","Ferrugem Comum"
"manchas circulares de coloração cinza com bordas escuras","Mancha de Alternaria"
"folhas com aspecto bronzeado e necrose nas pontas","Queima Bacteriana"
"lesões encharcadas no caule com odor forte","Podridão Mole"
"amarelecimento entre nervuras das folhas mais velhas","Deficiência de Nitrogênio"
"folhas novas amareladas e nervuras verdes","Deficiência de Ferro"
"manchas aquosas que evoluem para podridão","Podridão Negra"
"manchas em anel com esporulação central","Mofo Branco"
"caule com necrose basal e murcha repentina","Fusariose"
"lesões angulares com exsudato bacteriano","Pinta Bacteriana"
"folhas com pontuações marrons e queda precoce","Mancha-de-Phoma"
"manchas com bordas avermelhadas e interior claro","Mancha-de-Ramularia"
"murcha das folhas sem coloração anormal","Verticiliose"
"nódulos escuros nas raízes","Nematóide de Galha"
"raízes com lesões negras e crescimento atrofiado","Nematóide de Lesão"
"manchas concêntricas com esporos cinzentos","Mancha de Alternaria"
"folhas novas com enrolamento e encurtamento","Viroses"
"clorose uniforme em folhas basais","Deficiência de Enxofre"
"folhas com nervuras destacadas e amarelas","Deficiência de Manganês"
"folhas superiores com necrose entre nervuras","Deficiência de Cobre"
"manchas grandes e irregulares que se unem","Cercosporiose"
"desfolha acentuada com presença de esporos","Ferrugem Asiática"
"necrose na base das hastes jovens","Tombamento de Mudas"
"manchas com aparência de alvo de tiro","Mancha Olho de Rã"
"folhas com manchas secas de centro claro e bordas avermelhadas","Mancha Foliar"
"brotos com aparência queimadas","Míldio"
"pontos brancos que se espalham como pó","Oídio"
"folhas jovens retorcidas e sem vigor","Deficiência de Boro"
"manchas com exsudato viscoso em clima úmido","Bacteriose"
"lesões arredondadas nas vagens com podridão interna","Antracnose"
"manchas marrons na haste e podridão na raiz","Podridão Vermelha"
"presença de lagartas mastigando folhas e brotos","Lagarta-do-cartucho"
"furos circulares nas folhas com bordas irregulares","Lagarta falsa-medideira"
"manchas prateadas e presença de insetos minúsculos nas folhas","Trips"
"presença de ovos, ninfas e adultos sugando a seiva","Mosca-branca"
"furinhos alinhados nas vagens ou folhas, com presença de besouros","Vaquinha (Diabrotica spp.)"
"pontos brancos e necrose nas folhas e hastes causados por picadas","Percevejo-marrom"
"folhas enroladas e crescimento atrofiado devido à sucção de seiva","Pulgão-verde"
"áreas circulares com folhas mortas no meio da lavoura","Capim-amargoso"
"manchas vermelhas nas folhas que evoluem para necrose total","Picão-preto"
"competição com a cultura e folhas alongadas e lisas na base","Capim-colonião"
"planta de folhas largas e crescimento agressivo entre linhas","Caruru"
"folhas verdes escuras com formato lanceolado, resistente ao controle","Buva"
"presença de planta rasteira com folhas pequenas e muitos ramos","Erva-quente"
"folhas cobertas por pelos e hastes avermelhadas entre a cultura","Corda-de-viola"
"manchas roxas em plantas invasoras competindo com a cultura","Mentrasto"




Aumentar o dataset (recomendado):

texto,label
"folhas amareladas com pontas queimadas","Deficiência de Potássio"
"manchas circulares com halo amarelado nas folhas","Mancha-alvo"
"pústulas alaranjadas na face inferior das folhas","Ferrugem Asiática"
"folhas secas e caindo precocemente","Cercospora"
"manchas pequenas marrons com centro claro","Septoriose"
"manchas brancas com micélio na superfície","Oídio"
"lesões aquosas que se tornam marrons","Antracnose"
"folhas enroladas e cloróticas","Virose"
"folhas com margens necrosadas e crescimento reduzido","Deficiência de Magnésio"
"manchas púrpuras nas bordas das folhas mais velhas","Deficiência de Fósforo"
"folhas novas deformadas e cloróticas","Deficiência de Zinco"
"manchas pretas irregulares nos caules e folhas","Podridão de Esclerotinia"
"pontos escuros e dispersos nas folhas","Mancha Parda"
"pústulas marrons no verso das folhas","Ferrugem Comum"
"manchas circulares de coloração cinza com bordas escuras","Mancha de Alternaria"
"folhas com aspecto bronzeado e necrose nas pontas","Queima Bacteriana"
"lesões encharcadas no caule com odor forte","Podridão Mole"
"amarelecimento entre nervuras das folhas mais velhas","Deficiência de Nitrogênio"
"folhas novas amareladas e nervuras verdes","Deficiência de Ferro"
"manchas aquosas que evoluem para podridão","Podridão Negra"
"manchas em anel com esporulação central","Mofo Branco"
"caule com necrose basal e murcha repentina","Fusariose"
"lesões angulares com exsudato bacteriano","Pinta Bacteriana"
"folhas com pontuações marrons e queda precoce","Mancha-de-Phoma"
"manchas com bordas avermelhadas e interior claro","Mancha-de-Ramularia"
"murcha das folhas sem coloração anormal","Verticiliose"
"nódulos escuros nas raízes","Nematóide de Galha"
"raízes com lesões negras e crescimento atrofiado","Nematóide de Lesão"
"folhas novas com enrolamento e encurtamento","Viroses"
"clorose uniforme em folhas basais","Deficiência de Enxofre"
"folhas com nervuras destacadas e amarelas","Deficiência de Manganês"
"folhas superiores com necrose entre nervuras","Deficiência de Cobre"
"manchas grandes e irregulares que se unem","Cercosporiose"
"desfolha acentuada com presença de esporos","Ferrugem Asiática"
"necrose na base das hastes jovens","Tombamento de Mudas"
"manchas com aparência de alvo de tiro","Mancha Olho de Rã"
"folhas com manchas secas de centro claro e bordas avermelhadas","Mancha Foliar"
"brotos com aparência queimadas","Míldio"
"pontos brancos que se espalham como pó","Oídio"
"folhas jovens retorcidas e sem vigor","Deficiência de Boro"
"manchas com exsudato viscoso em clima úmido","Bacteriose"
"lesões arredondadas nas vagens com podridão interna","Antracnose"
"manchas marrons na haste e podridão na raiz","Podridão Vermelha"
"presença de lagartas mastigando folhas e brotos","Lagarta-do-cartucho"
"furos circulares nas folhas com bordas irregulares","Lagarta falsa-medideira"
"manchas prateadas e presença de insetos minúsculos nas folhas","Trips"
"presença de ovos, ninfas e adultos sugando a seiva","Mosca-branca"
"furinhos alinhados nas vagens ou folhas, com presença de besouros","Vaquinha (Diabrotica spp.)"
"pontos brancos e necrose nas folhas e hastes causados por picadas","Percevejo-marrom"
"folhas enroladas e crescimento atrofiado devido à sucção de seiva","Pulgão-verde"
"áreas circulares com folhas mortas no meio da lavoura","Capim-amargoso"
"manchas vermelhas nas folhas que evoluem para necrose total","Picão-preto"
"competição com a cultura e folhas alongadas e lisas na base","Capim-colonião"
"planta de folhas largas e crescimento agressivo entre linhas","Caruru"
"folhas verdes escuras com formato lanceolado, resistente ao controle","Buva"
"presença de planta rasteira com folhas pequenas e muitos ramos","Erva-quente"
"folhas cobertas por pelos e hastes avermelhadas entre a cultura","Corda-de-viola"
"manchas roxas em plantas invasoras competindo com a cultura","Mentrasto"
"folhas com textura pegajosa e presença de fumagina","Pulgão"
"folhas com pequenos furos e teias finas","Ácaro-rajado"
"caules com lesões escuras e murcha progressiva","Rhizoctonia"
"folhas com manchas esbranquiçadas que se tornam acinzentadas","Mofo Cinzento"
"raízes com podridão marrom e odor desagradável","Pythium"
"folhas com bordas queimadas e crescimento lento","Deficiência de Cálcio"
"manchas escuras com bordas amareladas nas vagens","Cercospora"
"folhas com manchas em mosaico e deformação","Vírus do Mosaico"
"presença de larvas brancas no interior das raízes","Larva de Raiz"
"folhas mastigadas com bordas irregulares","Lagarta-rosca"
"caules com furos e presença de serragem","Broca-do-caule"
"folhas com pontos brilhantes e pegajosos","Cochonilha"
"manchas acinzentadas com bordas escuras nas folhas","Antracnose Foliar"
"folhas com clorose e nervuras esverdeadas","Deficiência de Molibdênio"
"raízes com crescimento reduzido e nódulos amarelados","Nematóide Reniforme"
"folhas com aparência enrugada e manchas prateadas","Tripes"
"plantas com crescimento atrofiado e raízes escuras","Fusarium"
"folhas com pequenos pontos pretos e queda prematura","Mancha Angular"
"manchas escuras com textura aveludada nas folhas","Mancha de Diplodia"
"folhas com bordas amareladas e centro necrosado","Queima Foliar"
"caules com lesões acinzentadas e colapso da planta","Podridão de Colletotrichum"
"folhas com manchas marrons e textura seca","Mancha de Ascochyta"
"presença de teias e folhas amareladas","Ácaro-branco"
"folhas com furos grandes e presença de fezes","Lagarta-das-folhas"
"plantas invasoras com flores amarelas e crescimento rápido","Dente-de-leão"
"folhas largas com bordas serrilhadas entre a cultura","Losna"
"plantas rasteiras com flores brancas e raízes profundas","Tiririca"
"folhas com textura áspera e crescimento entre linhas","Capim-pé-de-galinha"
"plantas com flores roxas e competição por nutrientes","Trapoeraba"
"folhas com manchas escuras e bordas cloróticas","Mancha de Corynespora"
"caules com lesões marrons e exsudato pegajoso","Bacteriose de Xanthomonas"
"folhas com textura aveludada e manchas brancas","Mofo de Peronospora"
"raízes com pequenos cistos amarelados","Nematóide de Cisto"
"folhas com bordas onduladas e manchas em mosaico","Vírus do Mosaico do Tabaco"
"folhas com pontos amarelos e queda precoce","Mancha de Myrothecium"
"caules com rachaduras e podridão interna","Podridão de Phytophthora"
"folhas com manchas cinzentas e esporos visíveis","Mancha de Stemphylium"
"folhas com aparência de queimado e colapso rápido","Murcha de Sclerotium"
"folhas com pequenos orifícios e presença de besouros pequenos","Pulguinha"
"folhas com manchas pegajosas e presença de insetos alados","Mosca-das-folhas"
"plantas com crescimento lento e folhas amareladas na base","Deficiência de Boro"
"folhas com nervuras escuras e clorose entre elas","Deficiência de Potássio"
"caules com lesões escuras e colapso da planta jovem","Damping-off"
"folhas com manchas acinzentadas e textura seca","Mancha de Cercospora"
"folhas com furos irregulares e presença de larvas verdes","Lagarta-mede-palmo"
"plantas invasoras com folhas estreitas e crescimento denso","Capim-arroz"
"folhas com manchas marrons e bordas secas","Mancha de Bipolaris"
"folhas com textura pegajosa e presença de insetos pretos","Pulgão-preto"
"raízes com lesões escuras e odor fétido","Podridão de Rhizoctonia"
"folhas com manchas amarelas e bordas necrosadas","Mancha de Colletotrichum"
"folhas com bordas secas e textura quebradiça","Deficiência de Água"
"manchas acinzentadas com bordas escuras nos frutos","Mancha de Botrytis"
"folhas com pontos brilhantes e pegajosos devido a insetos","Pulgão-vermelho"
"caules com lesões escuras e textura encharcada","Podridão de Pythium"
"folhas com manchas em forma de anel e centro acinzentado","Mancha de Rhynchosporium"
"folhas com clorose severa e crescimento atrofiado","Deficiência de Zinco"
"raízes com podridão preta e colapso da planta","Podridão de Fusarium"
"folhas com pequenos pontos brancos e teias visíveis","Ácaro-vermelho"
"folhas com bordas amareladas e textura enrugada","Vírus do Enrolamento Foliar"
"plantas com crescimento lento e folhas pequenas","Deficiência de Cálcio"
"folhas com manchas escuras e textura aveludada","Mancha de Helminthosporium"
"caules com rachaduras longitudinais e podridão","Podridão de Sclerotium"
"folhas com furos grandes e presença de larvas marrons","Lagarta-da-espiga"
"plantas invasoras com folhas largas e flores brancas","Leiteiro"
"folhas com manchas prateadas e insetos pequenos visíveis","Thrips"
"folhas com textura pegajosa e presença de fumagina preta","Cochonilha-algodão"
"folhas com manchas marrons e bordas cloróticas","Mancha de Phakopsora"
"caules com lesões escuras e murcha das folhas superiores","Murcha Bacteriana"
"folhas com pontos pretos e queda prematura","Mancha de Nigrospora"
"raízes com nódulos brancos e crescimento reduzido","Nematóide de Cisto"
"folhas com manchas em mosaico e deformação severa","Vírus do Mosaico do Tomate"
"folhas com bordas necrosadas e textura seca","Deficiência de Magnésio"
"caules com lesões marrons e colapso da planta","Podridão de Rhizoctonia"
"folhas com pequenos furos e presença de insetos alados","Mosca-minadora"
"plantas invasoras com flores amarelas e raízes profundas","Guanxuma"
"folhas com manchas acinzentadas e esporos visíveis","Mancha de Septoria"
"folhas com textura enrugada e clorose severa","Deficiência de Ferro"
"caules com podridão basal e colapso da planta","Podridão de Phytophthora"
"folhas com manchas escuras e bordas amareladas","Mancha de Cercospora"
"folhas com furos irregulares e presença de larvas pretas","Lagarta-preta"
"plantas invasoras com folhas estreitas e crescimento rápido","Capim-marmelada"
"folhas com manchas prateadas e textura seca","Ácaro-branco"
"folhas com bordas queimadas e crescimento atrofiado","Deficiência de Potássio"
"caules com lesões escuras e exsudato viscoso","Bacteriose de Ralstonia"
"folhas com manchas amarelas e textura aveludada","Mofo de Peronospora"

Coletar mais dados reais de campo.
Usar ferramentas como nlpaug ou paráfrase com LLMs para gerar variações (ex.: "folhas amareladas com bordas secas" para "Deficiência de Potássio").


Pré-processamento:

Codificar rótulos com LabelEncoder.
Tokenizar textos com o tokenizer do DistilBERT.



Código para preparação:
pythonimport pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from transformers import DistilBertTokenizer, DistilBertForSequenceClassification
import torch

# Carregar dataset
data = pd.read_csv("plant_diseases.csv")

# Codificar rótulos
le = LabelEncoder()
data['label_encoded'] = le.fit_transform(data['label'])

# Dividir em treino e teste
train_texts, test_texts, train_labels, test_labels = train_test_split(
    data['texto'], data['label_encoded'], test_size=0.2, random_state=42
)

# Carregar tokenizer
tokenizer = DistilBertTokenizer.from_pretrained('distilbert-base-multilingual-cased')

# Tokenizar textos
def tokenize_data(texts, max_length=128):
    return tokenizer(
        texts.tolist(),
        max_length=max_length,
        padding=True,
        truncation=True,
        return_tensors='pt'
    )

train_encodings = tokenize_data(train_texts)
test_encodings = tokenize_data(test_texts)

# Criar dataset PyTorch
class PlantDiseaseDataset(torch.utils.data.Dataset):
    def __init__(self, encodings, labels):
        self.encodings = encodings
        self.labels = labels

    def __getitem__(self, idx):
        item = {key: val[idx] for key, val in self.encodings.items()}
        item['labels'] = torch.tensor(self.labels.iloc[idx], dtype=torch.long)
        return item

    def __len__(self):
        return len(self.labels)

train_dataset = PlantDiseaseDataset(train_encodings, train_labels)
test_dataset = PlantDiseaseDataset(test_encodings, test_labels)

3.2. Configuração do Modelo

Carregar o modelo distilbert-base-multilingual-cased.
Configurar o número de classes com base nos rótulos únicos.
Definir hiperparâmetros otimizados para o dataset pequeno.

Código para configuração:
pythonfrom transformers import DistilBertForSequenceClassification, Trainer, TrainingArguments

# Carregar modelo
num_labels = len(le.classes_)
model = DistilBertForSequenceClassification.from_pretrained(
    'distilbert-base-multilingual-cased',
    num_labels=num_labels
)

# Configurar hiperparâmetros
training_args = TrainingArguments(
    output_dir='./results',
    num_train_epochs=5,  # Aumentado devido ao dataset pequeno
    per_device_train_batch_size=8,
    per_device_eval_batch_size=8,
    warmup_steps=100,
    weight_decay=0.01,
    learning_rate=2e-5,
    logging_dir='./logs',
    logging_steps=10,
    evaluation_strategy="epoch",
    save_strategy="epoch",
    load_best_model_at_end=True,
)

# Configurar Trainer
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=test_dataset,
)

3.3. Treinamento

Treinar o modelo e salvar os arquivos necessários.

Código para treinamento:
python# Treinar modelo
trainer.train()

# Salvar modelo e tokenizer
model.save_pretrained("./plant_disease_model")
tokenizer.save_pretrained("./plant_disease_model")

# Salvar o LabelEncoder
import joblib
joblib.dump(le, "label_encoder.pkl")

3.4. Conversão para TFLite

Converter o modelo treinado para ONNX e depois para TFLite, garantindo compatibilidade com Flutter.
Exportar o vocabulário do tokenizer para uso no Flutter.

Código para conversão:
pythonimport onnx
import torch
from onnxruntime_tools import optimizer
import tf2onnx
import tensorflow as tf

# Exportar para ONNX
def convert_to_onnx(model, tokenizer, output_path="model.onnx"):
    model.eval()
    dummy_input = tokenizer(
        "folhas amareladas com pontas queimadas",
        return_tensors="pt",
        padding=True,
        truncation=True,
        max_length=128
    )
    torch.onnx.export(
        model,
        (dummy_input['input_ids'], dummy_input['attention_mask']),
        output_path,
        input_names=['input_ids', 'attention_mask'],
        output_names=['output'],
        dynamic_axes={
            'input_ids': {0: 'batch_size', 1: 'sequence'},
            'attention_mask': {0: 'batch_size', 1: 'sequence'},
            'output': {0: 'batch_size'}
        },
        opset_version=12
    )

convert_to_onnx(model, tokenizer)

# Otimizar ONNX
onnx_model = onnx.load("model.onnx")
optimized_model = optimizer.optimize_model(onnx_model)
optimized_model.save_model_to_file("model_optimized.onnx")

# Converter para TFLite
def convert_to_tflite(onnx_path, tflite_path="model.tflite"):
    onnx_model = onnx.load(onnx_path)
    tf_model, _ = tf2onnx.convert.from_onnx(
        onnx_model,
        input_names=['input_ids', 'attention_mask'],
        output_names=['output'],
        opset=12
    )
    converter = tf.lite.TFLiteConverter.from_saved_model("temp_tf_model")
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS
    ]
    tflite_model = converter.convert()
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)

convert_to_tflite("model_optimized.onnx")

# Exportar vocabulário do tokenizer
with open("vocab.txt", "w", encoding="utf-8") as f:
    for token in tokenizer.vocab:
        f.write(f"{token}\n")

4. Integração com Flutter
4.1. Configuração do Projeto Flutter

Criar um novo projeto Flutter:
bashflutter create plant_disease_classifier
cd plant_disease_classifier

Adicionar dependências no pubspec.yaml:
yamldependencies:
  flutter:
    sdk: flutter
  tflite_flutter: ^0.9.0
  path_provider: ^2.0.0
assets:
  - assets/model.tflite
  - assets/vocab.txt
  - assets/labels.txt

Copiar arquivos:

Copie model.tflite para assets/.
Copie vocab.txt (vocabulário do tokenizer) para assets/.
Crie labels.txt com os rótulos (um por linha):
textDeficiência de Potássio
Mancha-alvo
Ferrugem Asiática
Cercospora
Septoriose
Oídio
Antracnose
Virose
Copie para assets/.



4.2. Implementação do Tokenizer no Flutter

O DistilBERT usa um tokenizer WordPiece, que não tem uma implementação nativa em Flutter. Vamos criar uma versão simplificada para tokenizar textos com base no vocab.txt.

Código do tokenizer (lib/tokenizer.dart):
dartimport 'dart:io';

class BertTokenizer {
  Map<String, int> vocab = {};
  int maxLength = 128;

  BertTokenizer();

  Future<void> loadVocab(String vocabPath) async {
    final file = File(vocabPath);
    final lines = await file.readAsLines();
    for (int i = 0; i < lines.length; i++) {
      vocab[lines[i]] = i;
    }
  }

  List<int> tokenize(String text) {
    // Tokenização básica (divisão por palavras e subpalavras)
    List<String> tokens = ['[CLS]', ...text.toLowerCase().split(' '), '[SEP]'];
    List<int> inputIds = [];
    for (var token in tokens) {
      if (vocab.containsKey(token)) {
        inputIds.add(vocab[token]!);
      } else {
        inputIds.add(vocab['[UNK]']!); // Token desconhecido
      }
    }

    // Preenchimento até maxLength
    while (inputIds.length < maxLength) {
      inputIds.add(vocab['[PAD]']!);
    }
    return inputIds.take(maxLength).toList();
  }

  List<int> createAttentionMask(List<int> inputIds) {
    return List.generate(maxLength, (i) => i < inputIds.length && inputIds[i] != vocab['[PAD]']! ? 1 : 0);
  }
}
Nota: Este tokenizer é simplificado. Para maior precisão, use uma biblioteca como bert_tokenizer ou implemente o algoritmo WordPiece completo.
4.3. Carregar e Executar o Modelo TFLite

Usar o pacote tflite_flutter para carregar o modelo e realizar inferências.

Código principal (lib/main.dart):
dartimport 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'tokenizer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PlantDiseaseClassifier(),
    );
  }
}

class PlantDiseaseClassifier extends StatefulWidget {
  @override
  _PlantDiseaseClassifierState createState() => _PlantDiseaseClassifierState();
}

class _PlantDiseaseClassifierState extends State<PlantDiseaseClassifier> {
  Interpreter? _interpreter;
  BertTokenizer _tokenizer = BertTokenizer();
  List<String> _labels = [];
  String _result = '';
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadVocab();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('model.tflite');
    } catch (e) {
      print('Erro ao carregar o modelo: $e');
    }
  }

  Future<void> _loadVocab() async {
    await _tokenizer.loadVocab('assets/vocab.txt');
  }

  Future<void> _loadLabels() async {
    final file = await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
    _labels = file.split('\n');
  }

  Future<void> _predict(String text) async {
    if (_interpreter == null) return;

    // Tokenizar entrada
    final inputIds = _tokenizer.tokenize(text);
    final attentionMask = _tokenizer.createAttentionMask(inputIds);

    // Preparar entradas para o modelo
    var inputIdsArray = Int32List.fromList(inputIds).buffer.asInt32List();
    var attentionMaskArray = Int32List.fromList(attentionMask).buffer.asInt32List();
    var output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    // Executar inferência
    _interpreter!.runForMultipleInputs(
      [inputIdsArray, attentionMaskArray],
      {0: output},
    );

    // Obter resultado
    int predictedIndex = output[0].indexOf(output[0].reduce((a, b) => a > b ? a : b));
    setState(() {
      _result = _labels[predictedIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Classificador de Doenças de Plantas')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Descreva os sintomas'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _predict(_controller.text),
              child: Text('Classificar'),
            ),
            SizedBox(height: 20),
            Text('Resultado: $_result', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

4.4. Configuração do Ambiente Flutter

Habilitar assets:

Certifique-se de que assets/model.tflite, assets/vocab.txt e assets/labels.txt estão listados no pubspec.yaml.


Permissões (Android):

No android/app/src/main/AndroidManifest.xml, adicione:
xml<uses-permission android:name="android.permission.INTERNET"/>



Configurar TFLite:

Para Android, adicione no android/app/build.gradle:
gradleaaptOptions {
    noCompress 'tflite'
}

Para iOS, adicione no ios/Runner/Info.plist:
xml<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>





5. Testes

Testar o modelo treinado:

Após o treinamento, valide a acurácia no conjunto de teste (usando o código de avaliação do plano anterior).


Testar no Flutter:

Insira textos como "folhas amareladas com pontas queimadas" no aplicativo e verifique se o resultado é "Deficiência de Potássio".


Testes em campo:

Colete descrições reais de agricultores e teste a generalização do modelo.




6. Limitações

Dataset pequeno: As 8 amostras iniciais são insuficientes para um modelo robusto. Aumentar o dataset é essencial.
Tokenizer simplificado: A implementação do tokenizer em Flutter é básica. Para maior precisão, considere usar uma biblioteca WordPiece completa.
Perda de precisão: A conversão para TFLite pode reduzir ligeiramente a acurácia.
Desempenho em dispositivos: Modelos TFLite podem ser lentos em dispositivos antigos devido ao tamanho do DistilBERT.


7. Recomendações

Aumentar o dataset:

Adicione mais exemplos reais ou use geração de dados sintéticos.


Otimizar o modelo:

Aplique quantização ao TFLite para reduzir o tamanho e melhorar a velocidade:
pythonconverter.optimizations = [tf.lite.Optimize.DEFAULT]



Melhorar o tokenizer:

Integre uma biblioteca WordPiece ou pré-tokenize os textos no servidor.


UI/UX:

Adicione validação de entrada no Flutter (ex.: impedir textos vazios).
Inclua uma galeria de imagens ou exemplos de sintomas.




8. Estrutura do Projeto
textplant_disease_classifier/
├── assets/
│   ├── model.tflite
│   ├── vocab.txt
│   ├── labels.txt
├── lib/
│   ├── main.dart
│   ├── tokenizer.dart
├── python/
│   ├── train.py
│   ├── convert.py
├── pubspec.yaml

9. Conclusão
Este plano cobre o treinamento do modelo DistilBERT, sua conversão para TFLite e a integração em um aplicativo Flutter. O aplicativo permite que usuários insiram sintomas em texto e recebam a classificação da doença. Para melhorar a robustez, é crucial aumentar o dataset e refinar o tokenizer. Se precisar de ajuda com a implementação, testes ou adição de funcionalidades (ex.: suporte a imagens), é só avisar!