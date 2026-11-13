# ProPOM — coleta e processamento termográfico periorbital (GNU Octave)

Roda offline, em Octave puro (sem pacotes extras e sem Python). Use a interface gráfica do Octave para ter janelas de botões e a abertura automática do PDF.

## Uso

No Octave, dentro desta pasta, digite:

```octave
propom
```

O menu tem três botões:

| Botão | O que faz |
|---|---|
| **Nova coleta** | Registra a coleta: ambiente, checklist, aclimatação, participante, biometria, sinais vitais, questionário, orientação, posicionamento e captura. Não processa nada. |
| **Processar coleta e emitir relatório completo** | Escolhe uma coleta registrada, processa as imagens, calcula UR e temperatura no momento de cada imagem e emite os relatórios. |
| **Sair** | Fecha o menu. |

## Pastas (criadas automaticamente em `PROPOM_DADOS`)

Para mudar o local, edite `P.raiz` em `config_propom.m`, por exemplo para `C:\ProPOM`.

| Pasta | O que vai nela | Quem coloca |
|---|---|---|
| `TEMUR` | CSVs exportados do termo-higrômetro (Govee). Pode acumular vários arquivos: o programa junta todos e ordena por horário. | você, **depois** da coleta |
| `TERMOCSV\<código>` | CSVs das imagens térmicas da coleta | você, depois da captura |
| `TERMOJPG\<código>` | JPGs capturados pela câmera | você, depois da captura |
| `ANAMNESE\QUESTIONARIOS` | CSVs baixados do Mentaltracking | você, antes da coleta |
| `ANAMNESE\<código>` | `registro.csv` (checklist, biometria, sinais vitais, horários), `capturas.csv`, `questionario.csv` | programa |
| `ANAMNESE\identificacao_PRIVADO.csv` | código × nome × nascimento × sexo | programa |
| `RESULTADOS\<código>` | processamento térmico, `ambiente_por_imagem.csv` e relatórios em PDF | programa |
| `RESULTADOS\*_consolidado.csv` | tabelas de todas as coletas, sem nome nem data de nascimento | programa |

A pasta `PROPOM_DADOS` está no `.gitignore`: **dados de participantes não vão para o GitHub.**

## Nova coleta: sequência

1. **Ambiente.** Exige UR entre **40 e 60 %** e temperatura do protótipo entre **23 e 25 °C**. Os valores podem vir de uma leitura de até 10 min na pasta TEMUR ou ser digitados do visor do termo-higrômetro. Fora da faixa, você escolhe: reler, continuar com o desvio registrado ou encerrar.
2. **Checklist do dia da coleta.** Itens editáveis em `P.checklist`.
3. **Aclimatação.** O programa pergunta se o participante está aclimatado.
4. **Participante.** Nome, data de nascimento e sexo (**F** = feminino, **M** = masculino). Gera o código e cria as subpastas da coleta.
5. **Biometria.** Peso e altura; o IMC é calculado.
6. **Sinais vitais.** PAS, PAD, FC, FR, SpO2, temperatura corporal e local/método. Os campos são editáveis em `config_propom.m`, e Enter em branco registra "não medido".
7. **Questionário de autodeclaração de cognição.** Pergunta se foi respondido, importa o CSV de `ANAMNESE\QUESTIONARIOS` (você escolhe o arquivo e a resposta) e abre um campo de anotação.
8. **Preparação.** Confirma que o participante foi orientado e que o posicionamento foi checado.
9. **Captura.** Time-lapse de 10 s com bipe: 5 imagens de olhos abertos, depois 5 de olhos fechados. Em seguida pergunta se deseja mais alguma tomada.

O registro é gravado a cada etapa. Se algo travar no meio, o que já foi digitado fica salvo.

## Processamento: o que acontece

1. Os CSVs de `TERMOCSV\<código>` são associados às capturas pela ordem do nome do arquivo, e o programa pede sua confirmação.
2. As ROIs 3 × 3 são processadas para **OD e OE**.
3. UR e temperatura são calculadas **no momento de cada imagem**, como a média da leitura imediatamente anterior e da posterior. Exemplo: 10:00 → 40 % e 10:10 → 41 %; uma imagem às 10:06 fica com 40,5 %.
   - Para usar interpolação linear, mude `P.temur_metodo` para `'linear'`.
   - Sem leitura posterior, a célula fica em branco; o programa não extrapola. Por isso, exporte o CSV do Govee **depois** da coleta.
4. Relatórios em `RESULTADOS\<código>\`:
   - `relatorio_parcial_fisiologico_<código>.pdf`: checklist, biometria, sinais vitais e questionário.
   - `relatorio_parcial_ambiental_<código>.pdf`: checagem inicial, gráfico de UR e T com as faixas e o instante de cada imagem, e o valor no momento de cada imagem.
   - `relatorio_parcial_termico_<código>.pdf`: imagens com a ROI marcada e as 7 medidas da ROI para OD e OE (média ± DP das 5 imagens de cada condição).
   - `relatorio_completo_<código>.pdf`: as três páginas acima juntas. Usa o Ghostscript que já vem com o Octave para Windows.
5. As tabelas consolidadas são reconstruídas. Reprocessar uma coleta não duplica linhas.

## Lateralidade

O participante fica **de frente** para a câmera, então o **olho direito (OD) aparece à esquerda da imagem**. Todos os pontos, máscaras, colunas e relatórios usam a lateralidade do participante (OD/OE). Só troque `P.espelhamento` para `'espelhada'` se a câmera estiver com espelhamento ligado.

## Seleção da ROI (resumo)

1. **Pontos de referência.** Máscara do visor, ápice do dorso nasal e endocantos OD e OE.
2. **Região orbital.** Elipse de 40 × 35 mm ancorada no endocanto e orientada pelo eixo intercantal. Ela não depende da abertura palpebral.
3. **Quadrantes.** A órbita é dividida em quatro quadrantes que acompanham a inclinação da cabeça. A pele elegível é o quadrante superior medial.
4. **Seleção da janela.** Entre todas as janelas 3 × 3 inteiramente elegíveis, vale a de maior temperatura média.
5. **Medidas.** Máximo, mínimo, média, mediana, desvio padrão, variância e amplitude, sempre nos mesmos 9 pixels originais. Desvio padrão e variância são amostrais (n − 1).
6. **Correção manual.** Use `pontos_manuais.csv` na pasta das imagens, com as colunas `arquivo,N_lin,N_col,OD_lin,OD_col,OE_lin,OE_col`.
7. **Imagem de conferência.** Fica em `RESULTADOS\<código>\termico\conferencia\`:

| Cor | O que marca |
|---|---|
| Amarelo | borda útil do visor |
| Ciano | órbita |
| Laranja | eixos dos quadrantes |
| Verde | pele elegível |
| Vermelho | ROI do OD |
| Rosa | ROI do OE |
| Magenta | ápice nasal |
| Azul | endocantos |

## Validação

```octave
propom_roi('dados', 'saida');  testes_propom_roi('dados', 'saida')
```

São 18 testes automáticos, cobrindo:
- leitura e integridade das matrizes;
- caso sintético com resposta conhecida;
- recálculo das medidas a partir do CSV bruto;
- lateralidade OD/OE;
- média das leituras vizinhas do termo-higrômetro;
- código pseudonimizado;
- reprodutibilidade.

A pasta `dados` traz as 10 matrizes de exemplo. Nelas, a condição aberto/fechado é **suposta**.

## Pendências declaradas

- A classificação automática de olho aberto/fechado é exploratória. A classe sai como `indeterminado` até ser calibrada com rótulos confiáveis.
- O horário de cada imagem vem do relógio do computador no bipe do time-lapse. Mantenha o computador e o celular do Govee sincronizados.
