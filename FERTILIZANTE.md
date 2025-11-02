Ótimo—vamos direto ao ponto. Pelo que mostram as telas:

* Você coleta **massa por bandeja (g)** durante um percurso conhecido (**Distância Percorrida – m**).
* O app está usando **Faixa Efetiva** no denominador e **NÃO** está corrigindo a amostragem parcial das bandejas ⇒ por isso sai **0,5 kg/ha** e erro **-99,7%**.
* Além disso, o SQLite está quebrando porque você tenta gravar `List<double>` direto.

Abaixo vai um **método de cálculo** (e código) seguro e preciso **com base na tela 1**.

---

# Método de cálculo (baseado na tela 1)

### Entradas obrigatórias (todas editáveis)

* `paletaP_mm`, `paletaG_mm` (só para diagnóstico/relatório)
* `densidade_gL`, `rpm`, `velocidade_kmh` (diagnóstico/relatório)
* `taxaDesejada_kgHa`
* `distanciaPercorrida_m` (comprimento percorrido enquanto as bandejas coletam)
* `massasBandeja_g[]` (lista de massas das bandejas, em **gramas**)
* `larguraBandeja_m` (**NOVA**; se não existir no UI, adicione; em prática é \~0,20 m)

> **Por quê “largura da bandeja”?**
> As bandejas amostram só uma faixa estreita. Para estimar a taxa aplicada no **m²**, precisamos dividir pela **área amostrada** (= largura da bandeja × distância percorrida). Sem isso, a taxa fica artificialmente baixa.

---

### Fórmulas

1. **Média, desvio e CV**
   Use desvio **amostral** (n−1):

* `media_g = mean(massas)`
* `desvio_g = stddev_sample(massas)`
* `cv_percent = (desvio_g / media_g) * 100`

2. **Taxa Real (kg/ha)**
   Considere **todas** as bandejas válidas (as dentro da faixa que você marcar):

$$
\text{Taxa Real (kg/ha)}=
\frac{\sum m_i\ (\text{g}) \times 10}{\underbrace{(\text{N\_bandejas} \times \text{larguraBandeja\_m})}_{\text{largura total amostrada}}\times \text{distanciaPercorrida\_m}}
$$

> Observação importante: **não** use Faixa Efetiva no denominador para a **taxa**. A Faixa Efetiva serve para diagnóstico e definição do **espaçamento entre passadas**, não para converter massa→área amostrada.

3. **Erro (%)**

$$
\text{Erro \%}=\frac{\text{Taxa Real}-\text{Taxa Desejada}}{\text{Taxa Desejada}}\times 100
$$

4. **Faixa Efetiva (m)** – **diagnóstico, não entra na taxa**

* Se o usuário preencher **Faixa Esperada**, exiba-a.
* Caso contrário, **estime** (opcional) por função empírica das paletas/rpm/densidade. Mas **não** use na taxa.

---

### Checagens que evitam resultados absurdos

* `distanciaPercorrida_m > 0`, `larguraBandeja_m > 0`, `massasBandeja_g.isNotEmpty`, `taxaDesejada_kgHa > 0`.
* Se `sum(massas) < 1 g` e `distancia > 50 m`, avise: “massa muito baixa para o percurso; revise percurso/largura da bandeja”.
* Classificação do CV:

  * `<10%` Excelente, `10–20%` Moderado, `>20%` Ruim.

---

# Código Dart (cálculo e correções)

> **Use exatamente este método na sua camada de domínio**, mantendo as entradas da Tela 1.

```dart
class ResultadoCalibracao {
  final double taxaRealKgHa;
  final double erroPercent;
  final double mediaG;
  final double desvioG;
  final double cvPercent;
  final double? faixaEfetivaM; // só para exibição/diagnóstico

  ResultadoCalibracao({
    required this.taxaRealKgHa,
    required this.erroPercent,
    required this.mediaG,
    required this.desvioG,
    required this.cvPercent,
    this.faixaEfetivaM,
  });
}

class CalibracaoFertilizantesCalculator {
  static ResultadoCalibracao calcular({
    // Entradas de cálculo
    required List<double> massasBandejaG, // g
    required double distanciaPercorridaM, // m (coleta)
    required double larguraBandejaM,      // m (ex.: 0.20)
    required double taxaDesejadaKgHa,

    // Diagnóstico (não entram na taxa)
    double? faixaEsperadaM,
    double? paletaPmm,
    double? paletaGmm,
    int? rpm,
    double? densidade_gL,
    double? velocidadeKmh,
  }) {
    // ======= Validações
    if (distanciaPercorridaM <= 0) {
      throw ArgumentError('Distância percorrida deve ser > 0 m.');
    }
    if (larguraBandejaM <= 0) {
      throw ArgumentError('Largura da bandeja deve ser > 0 m.');
    }
    if (massasBandejaG.isEmpty) {
      throw ArgumentError('Informe as massas das bandejas (g).');
    }
    if (taxaDesejadaKgHa <= 0) {
      throw ArgumentError('Taxa desejada deve ser > 0 kg/ha.');
    }

    // ======= Estatística básica
    final n = massasBandejaG.length;
    final soma = massasBandejaG.fold<double>(0, (a, b) => a + b);
    final media = soma / n;

    double varianciaAmostral = 0;
    if (n > 1) {
      final sq = massasBandejaG
          .map((v) => (v - media) * (v - media))
          .fold<double>(0, (a, b) => a + b);
      varianciaAmostral = sq / (n - 1);
    }
    final desvio = varianciaAmostral > 0 ? Math.sqrt(varianciaAmostral) : 0.0;
    final cv = media > 0 ? (desvio / media) * 100.0 : 0.0;

    // ======= Taxa real (kg/ha)
    // Área amostrada = (N * larguraBandejaM) * distanciaPercorridaM
    // Conversão g → kg/ha (fator 10)
    final taxaRealKgHa =
        (soma * 10.0) / (n * larguraBandejaM * distanciaPercorridaM);

    // ======= Erro %
    final erroPercent = ((taxaRealKgHa - taxaDesejadaKgHa) / taxaDesejadaKgHa) * 100.0;

    // ======= Faixa efetiva para exibição (opcional)
    final faixaEfetivaM = faixaEsperadaM; // exibir se houver

    return ResultadoCalibracao(
      taxaRealKgHa: taxaRealKgHa.isFinite ? taxaRealKgHa : 0,
      erroPercent: erroPercent.isFinite ? erroPercent : 0,
      mediaG: media.isFinite ? media : 0,
      desvioG: desvio.isFinite ? desvio : 0,
      cvPercent: cv.isFinite ? cv : 0,
      faixaEfetivaM: faixaEfetivaM,
    );
  }
}

// Utilitário simples (evita importar dart:math no seu domínio)
class Math {
  static double sqrt(double v) => v <= 0 ? 0 : v.toDouble().sqrt();
}

extension _Sqrt on double {
  double sqrt() => (this).toDouble() >= 0 ? _sqrtNewton(this) : double.nan;
  static double _sqrtNewton(double x) {
    if (x == 0) return 0;
    double r = x, last;
    do {
      last = r;
      r = 0.5 * (r + x / r);
    } while ((r - last).abs() > 1e-12);
    return r;
  }
}
```

> **Observação:** se você já usa `dart:math`, troque o utilitário `Math.sqrt` por `sqrt` de `dart:math`.

---

## Correção do erro no SQLite (List<double>)

Você está tentando salvar `List<double>` direto no campo. Grave como **JSON** (ou crie uma tabela filha).

### Serializar para TEXT

```dart
import 'dart:convert';

// salvar
final coletasJson = jsonEncode(massasBandejaG); // "[1.0,1.1,0.9,...]"
// ... insira em coluna TEXT

// ler
final List<dynamic> raw = jsonDecode(coletasJson);
final massas = raw.map((e) => (e as num).toDouble()).toList();
```

**Schema (exemplo):**

```sql
CREATE TABLE calibracao_fertilizantes (
  id INTEGER PRIMARY KEY,
  ...,
  massas_bandeja_json TEXT NOT NULL
);
```

> Alternativa (mais relacional): criar `calibracao_bandeja (id_calibracao, ordem, massa_g)`.

---

## Por que seu erro de -99,7% acontece?

Com seus números de exemplo no print 2:

* `sum(massas) ≈ 6 g` (ex.: \[1.0,1.1,0.9,1.0,2.0])
* `N = 5`
* `larguraBandeja = 0,20 m`
* Se `distancia = 100 m` ⇒
  `taxaReal = (6 * 10) / (5 * 0,20 * 100) = 60 / 100 = 0,6 kg/ha`
  Comparando com `180 kg/ha` ⇒ **\~ -99,7%**.

Ou seja, **as massas coletadas estão muito baixas para o percurso** (ou a distância usada está grande demais para a massa capturada). Com o método acima você terá um diagnóstico consistente e saberá quando repetir o teste (ex.: reduzir a distância para 10–20 m, ajustar bandejas, etc.).

---

## Checklist de qualidade para não errar mais

* [ ] Adicionar **Largura da Bandeja (m)** na tela (obrigatório para a taxa).
* [ ] Usar a **fórmula da área amostrada** (N × larguraBandeja × distância).
* [ ] **Não** usar Faixa Efetiva no denominador da taxa.
* [ ] Validar entradas e exibir avisos (massa total baixa, distância incompatível, CV > 20%).
* [ ] Serializar `massasBandeja_g` em JSON ao salvar no SQLite.

Se quiser, eu adapto o seu repositório com essa função (camada domínio + service + reparo do DAO) e te devolvo o trecho de `.dart` pronto para colar.
