% ANALISE  Modelo para um novo experimento
%
%   COMO USAR
%   1. Copie a pasta experimentos/_modelo para experimentos/03_nome_do_experimento
%      (o número define a ordem na página; pastas que começam com "_" são ignoradas).
%   2. Coloque os arquivos de dados em dados/.
%   3. Edite este script e o pagina.html.
%   4. Rode  executar_tudo  no Octave (ou envie ao GitHub, que roda sozinho).
%
%   O QUE ESTE SCRIPT RECEBE
%     - O diretório corrente é a pasta do experimento (use caminhos como 'dados/arquivo.csv').
%     - pasta_saida : pasta onde salvar figuras (PNG) e resultados (CSV).
%     - Todas as funções de lib/ (wilcoxon_pareado, tendencia_linear, psd_welch, fmt, ...).
%
%   O QUE ESTE SCRIPT DEVE PREENCHER (struct R)
%     R.resumo      frase curta para o cartão da página inicial
%     R.destaques   cell {rótulo, valor; ...} com 2 a 3 números-chave para o cartão
%     R.val.nome    textos/números citados no pagina.html como {{val:nome}}
%     R.tab.nome    tabelas HTML (use html_tabela) citadas como {{tab:nome}}
%     R.fig.nome    nome do PNG salvo em pasta_saida, citado como {{fig:nome|legenda}}

% ============================ CONFIGURAÇÃO ================================
cfg.arquivo = fullfile('dados', 'exemplo.csv');
% ==========================================================================

C = cores_propom();

% --- leitura (exemplo: CSV com cabeçalho DATA_HORA,TEMP,UR) ---------------
% [tn, temp, ur] = ler_serie_csv(cfg.arquivo);

% --- dados de demonstração (apague ao usar dados reais) -------------------
x = (1:100)';
y = 20 + 0.01 * x + 0.1 * sin(x / 5);

% --- estatística -----------------------------------------------------------
T = tendencia_linear(x, y);
R.val.inclinacao = fmt(T.b, 4);
R.val.ic = ['[' fmt(T.ic(1), 4) '; ' fmt(T.ic(2), 4) ']'];
R.tab.resumo = html_tabela({'Medida', 'Valor'}, ...
  {'Inclinação', fmt(T.b, 4); 'R²', fmt(T.r2, 3); 'n efetivo', fmt(T.n_ef, 0)}, 'Nota da tabela.');

% --- figura ------------------------------------------------------------------
h = fig_nova(8, 3.2);
plot(x, y, 'color', C.pro);
eixo_estilo(gca, 'Amostra', 'Valor', 'Título do gráfico');
fig_salvar(h, fullfile(pasta_saida, 'serie.png'));
R.fig.serie = 'serie.png';

% --- resultados para download ------------------------------------------------
escrever_csv(fullfile(pasta_saida, 'resultados.csv'), {'medida', 'valor'}, {'inclinacao'; 'r2'}, [T.b; T.r2]);

% --- cartão da página inicial ----------------------------------------------
R.resumo = 'Descrição curta do experimento.';
R.destaques = {'Inclinação', [fmt(T.b, 4) ' unid./amostra']};
