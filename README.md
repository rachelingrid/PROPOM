# ProPOM — validação metrológica da cabine

Repositório dos ensaios de caracterização da cabine termográfica do framework **ProPOM** (Proxy Periorbital Medial).
Dissertação de mestrado, Programa de Engenharia Biomédica — PEB/COPPE/UFRJ.

**Página de resultados:** https://rachelingrid.github.io/PROPOM/

Tudo é calculado em **GNU Octave puro** (sem pacotes adicionais). A cada envio para a branch `main`, o GitHub
roda as análises do zero e publica a página com os gráficos, as tabelas e o código-fonte que os gerou.

## Experimentos

| Pasta | Experimento |
|---|---|
| `experimentos/01_deriva_termica` | Deriva térmica do termógrafo dentro da cabine (lotes 1 e 2) |
| `experimentos/02_umidade_temperatura` | Temperatura e umidade: laboratório × cabine em quatro regimes do ar-condicionado |

## Rodar no próprio computador (offline)

1. Instale o [GNU Octave](https://octave.org) (versão 8 ou mais recente).
2. Baixe este repositório (botão **Code → Download ZIP**) e descompacte.
3. Abra o Octave, vá até a pasta do repositório e digite:

   ```
   executar_tudo
   ```

4. Abra `site/index.html` no navegador.

## Acrescentar um experimento

1. Copie a pasta `experimentos/_modelo` para `experimentos/03_nome` (o número define a ordem).
2. Coloque os dados em `experimentos/03_nome/dados/`.
3. Edite `analise.m` (cálculos, figuras) e `pagina.html` (texto). As instruções estão no topo de `analise.m`.
4. Rode `executar_tudo` para conferir e envie ao GitHub.

No `pagina.html`, os resultados entram por marcadores que o Octave substitui:
`{{val:nome}}` (número ou texto), `{{tab:nome}}` (tabela) e `{{fig:nome|legenda}}` (figura).

## Estrutura

```
executar_tudo.m        roda tudo e gera a pasta site/
lib/                   funções comuns (estatística, gráficos, geração da página)
experimentos/NN_nome/  analise.m, pagina.html, dados/ — um por experimento
recursos/              estilo da página e texto da página inicial
.github/workflows/     automação: instala o Octave, roda e publica
```

## Biblioteca estatística (`lib/`)

Implementações próprias, validadas contra o R e o SciPy com os dados do Experimento 02:

- `wilcoxon_pareado` — postos sinalizados (convenção do `wilcox.test` do R), r = z/√n, r rank-bisserial, n efetivo e p ajustado
- `levene_bf` — Levene centrado na mediana (Brown–Forsythe)
- `shapiro_wilk` — algoritmo de Royston (1995)
- `tendencia_linear` — mínimos quadrados com IC 95% corrigido para autocorrelação, e inclinação de Theil–Sen
- `psd_welch`, `potencia_banda`, `periodo_autocorr` — análise espectral e período de ciclos

© Rachel Ingrid Pereira da Rocha Jannuzzi. Todos os direitos reservados — ver [LICENSE](LICENSE).
