% ANALISE  Experimento 01 — Deriva térmica do termógrafo dentro da cabine
%
%   Entrada : dados/analise_lote_1.csv e dados/analise_lote_2.csv, gerados pelo
%             scripts_originais/AMT.m (uma linha por quadro térmico 320x240).
%   Saída   : figuras e CSVs em pasta_saida; struct R usada por pagina.html.
%
%   Lote 1: cabine aclimatada, sem nenhuma emissão de IR  -> deriva do equipamento.
%   Lote 2: emissão de IR externa, a 7 cm da parede da cabine; durante a
%           aquisição, evento climático (tempestade), com o ar-condicionado em DRY.

% ============================ CONFIGURAÇÃO ================================
cfg.dt_min  = NaN;   % intervalo entre quadros, em minutos (NaN = ainda não informado)
cfg.n_borda = 5;     % quadros médios no início e no fim para medir a variação total

% Lote 1: trecho final usado para verificar se a deriva cessou (quadros)
cfg.l1_final = [558 588];

% Lote 2: fases (quadros), definidas por inspeção da série de desvio-padrão espacial
cfg.fases = struct('nome', {'Aquecimento', 'Patamar', 'Perturbação'}, ...
                   'ini',  {589, 601, 663}, ...
                   'fim',  {600, 662, 693});
% Lote 2: janelas de comparação antes x depois da perturbação (quadros)
cfg.antes  = [653 662];   % 10 quadros finais do patamar
cfg.depois = [684 693];   % 10 quadros finais do lote
% ==========================================================================

C = cores_propom();
L1 = ler_lote(fullfile('dados', 'analise_lote_1.csv'));
L2 = ler_lote(fullfile('dados', 'analise_lote_2.csv'));
nb = cfg.n_borda;

% ======================================================= LOTE 1 ==========
vars = {'tmax', 'tmed', 'tmin', 'tmediana'};
rot  = {'Máxima', 'Média', 'Mínima', 'Mediana'};
mf = L1.quadro >= cfg.l1_final(1) & L1.quadro <= cfg.l1_final(2);
linhas = cell(numel(vars), 7);
csv = zeros(numel(vars), 11);
for k = 1:numel(vars)
  y = L1.(vars{k});
  ini = mean(y(1:nb));  fim = mean(y(end-nb+1:end));
  T  = tendencia_linear(L1.quadro, y);
  Tf = tendencia_linear(L1.quadro(mf), y(mf));
  linhas(k, :) = {rot{k}, fmt(ini, 2), fmt(fim, 2), fmt(fim - ini, 2, true), ...
                  [fmt(T.b, 4) ' <span class="ic">[' fmt(T.ic(1), 4) '; ' fmt(T.ic(2), 4) ']</span>'], ...
                  [fmt(Tf.b, 4) ' <span class="ic">[' fmt(Tf.ic(1), 4) '; ' fmt(Tf.ic(2), 4) ']</span>'], ...
                  fmt(T.sen, 4)};
  csv(k, :) = [ini fim fim-ini T.b T.ic T.sen Tf.b Tf.ic T.n_ef];
  tend.(vars{k}) = T;  tfin.(vars{k}) = Tf;  delta.(vars{k}) = fim - ini;
end
R.tab.lote1 = html_tabela( ...
  {'Temperatura do quadro (°C)', sprintf('Início (%d quadros)', nb), sprintf('Fim (%d quadros)', nb), 'Variação', ...
   'Inclinação no lote [IC 95%]', sprintf('Inclinação nos quadros %d–%d [IC 95%%]', cfg.l1_final), 'Sen no lote'}, ...
  linhas, ['Inclinações em °C por quadro. IC 95% corrigido para a autocorrelação dos resíduos ' ...
           '(n efetivo, aproximação AR(1)). Sen = inclinação robusta de Theil–Sen.']);
escrever_csv(fullfile(pasta_saida, 'lote1_tendencias.csv'), ...
  {'variavel', 'inicio_C', 'fim_C', 'variacao_C', 'incl_lote', 'incl_lote_ic_inf', 'incl_lote_ic_sup', 'sen_lote', ...
   'incl_final', 'incl_final_ic_inf', 'incl_final_ic_sup', 'n_efetivo_lote'}, rot, csv);

% Modelo de acomodação exponencial simples (teste de adequação)
E = ajuste_exponencial(L1.quadro, L1.tmed);
res_exp = L1.tmed - E.yhat;
R.val.exp_tau  = fmt(E.tau, 1);
R.val.exp_r2   = fmt(E.r2, 2);
R.val.exp_rho  = fmt(autocorr_lag1(res_exp), 2);
R.val.lin_r2   = fmt(tend.tmed.r2, 2);

R.val.n1      = sprintf('%d', numel(L1.quadro));
R.val.q1_ini  = sprintf('%d', L1.quadro(1));
R.val.q1_fim  = sprintf('%d', L1.quadro(end));
R.val.nb      = sprintf('%d', nb);
R.val.d_tmed  = fmt(delta.tmed, 2, true);
R.val.d_tmax  = fmt(delta.tmax, 2, true);
R.val.d_tmin  = fmt(delta.tmin, 2, true);
R.val.fin_ini = sprintf('%d', cfg.l1_final(1));
R.val.fin_fim = sprintf('%d', cfg.l1_final(2));
R.val.fin_b   = fmt(tfin.tmed.b, 4);
R.val.fin_ic  = ['[' fmt(tfin.tmed.ic(1), 4) '; ' fmt(tfin.tmed.ic(2), 4) ']'];
R.val.queda3  = fmt(L1.tmed(3) - L1.tmed(1), 2, true);
if ~isnan(cfg.dt_min)
  R.val.unidade_tempo = sprintf(['Intervalo entre quadros: %s min. Em unidades de tempo, a inclinação média ' ...
                                 'no lote é de %s °C/min.'], fmt(cfg.dt_min, 2), fmt(tend.tmed.b / cfg.dt_min, 4));
else
  R.val.unidade_tempo = ['O intervalo entre quadros ainda não foi registrado nesta versão ' ...
                         '(<code>cfg.dt_min</code> em <code>analise.m</code>); por isso, as inclinações estão em °C por quadro.'];
end

% Dispersão espacial (dentro de cada quadro)
dv = {'dp', 'amp'};  drot = {'Desvio-padrão espacial', 'Amplitude (máx − mín)'};
linhas = cell(2, 6);
for k = 1:2
  x = L1.(dv{k});
  linhas(k, :) = {drot{k}, fmt(median(x), 2), fmt(iqr_amostral(x), 2), fmt(median(abs(x - median(x))), 2), ...
                  [fmt(min(x), 2) ' – ' fmt(max(x), 2)], fmt(mean(x(end-nb+1:end)) - mean(x(1:nb)), 2, true)};
end
R.tab.dispersao_lote1 = html_tabela({'Medida (°C)', 'Mediana', 'IIQ', 'MAD', 'Mín – máx', 'Variação início → fim'}, linhas, ...
  'IIQ = intervalo interquartil; MAD = desvio absoluto mediano.');

% Figura — séries do lote 1
h = fig_nova(8, 3.4);
hold on;
hl = [plot(L1.quadro, L1.tmax, 'color', C.lab), plot(L1.quadro, L1.tmed, 'color', C.pro), ...
      plot(L1.quadro, L1.tmin, 'color', C.c3), plot(L1.quadro, E.yhat, '--', 'color', C.ajuste, 'linewidth', 1)];
hold off;
xlim([L1.quadro(1) L1.quadro(end)]);
legend(hl, {'Máxima', 'Média', 'Mínima', 'Exponencial ajustada à média'}, 'location', 'northeast', 'box', 'off');
eixo_estilo(gca, 'Quadro (número do arquivo)', 'Temperatura (°C)', 'Lote 1 — cabine fechada, sem emissão de IR');
fig_salvar(h, fullfile(pasta_saida, 'lote1_series.png'));
R.fig.lote1_series = 'lote1_series.png';

% Figura — resíduos do modelo exponencial e DP espacial
h = fig_nova(8, 4.2);
subplot(2, 1, 1);
plot(L1.quadro, res_exp, '.-', 'color', C.pro, 'markersize', 8, 'linewidth', 0.8);
hold on; plot(L1.quadro([1 end]), [0 0], '-', 'color', C.sec, 'linewidth', 0.6); hold off;
xlim([L1.quadro(1) L1.quadro(end)]);
eixo_estilo(gca, '', 'Resíduo (°C)', 'Temperatura média menos a exponencial ajustada');
subplot(2, 1, 2);
plot(L1.quadro, L1.dp, 'color', C.pro);
xlim([L1.quadro(1) L1.quadro(end)]);
eixo_estilo(gca, 'Quadro (número do arquivo)', 'DP espacial (°C)', 'Desvio-padrão dentro do quadro');
fig_salvar(h, fullfile(pasta_saida, 'lote1_residuos.png'));
R.fig.lote1_residuos = 'lote1_residuos.png';

% ======================================================= LOTE 2 ==========
% Fases (medianas)
nf = numel(cfg.fases);
linhas = cell(nf, 7);
csv = zeros(nf, 7);
for k = 1:nf
  m = L2.quadro >= cfg.fases(k).ini & L2.quadro <= cfg.fases(k).fim;
  med = [median(L2.tmax(m)) median(L2.tmed(m)) median(L2.tmin(m)) median(L2.dp(m)) median(L2.amp(m))];
  linhas(k, :) = [{cfg.fases(k).nome, sprintf('%d–%d (%d)', cfg.fases(k).ini, cfg.fases(k).fim, sum(m))}, ...
                  arrayfun(@(v) fmt(v, 2), med, 'uniformoutput', false)];
  csv(k, :) = [cfg.fases(k).ini cfg.fases(k).fim med];
end
R.tab.fases_lote2 = html_tabela({'Fase', 'Quadros (n)', 'Máxima', 'Média', 'Mínima', 'DP espacial', 'Amplitude'}, ...
  linhas, 'Medianas dentro de cada fase, em °C.');
escrever_csv(fullfile(pasta_saida, 'lote2_fases.csv'), ...
  {'fase', 'quadro_ini', 'quadro_fim', 'med_tmax', 'med_tmed', 'med_tmin', 'med_dp', 'med_amp'}, {cfg.fases.nome}, csv);

% Antes x depois da perturbação (janelas curtas, para não misturar a subida do patamar)
ma = L2.quadro >= cfg.antes(1)  & L2.quadro <= cfg.antes(2);
md = L2.quadro >= cfg.depois(1) & L2.quadro <= cfg.depois(2);
v2 = {'tmax', 'tmin', 'tmed', 'dp', 'amp'};
r2 = {'Máxima', 'Mínima', 'Média', 'DP espacial', 'Amplitude'};
linhas = cell(numel(v2), 5);
csv = zeros(numel(v2), 4);
for k = 1:numel(v2)
  a = mean(L2.(v2{k})(ma));  b = mean(L2.(v2{k})(md));
  linhas(k, :) = {r2{k}, fmt(a, 2), fmt(b, 2), fmt(b - a, 2, true), fmt(100 * (b - a) / a, 1, true)};
  csv(k, :) = [a b b-a 100*(b-a)/a];
  dd.(v2{k}) = b - a;  dp_.(v2{k}) = 100 * (b - a) / a;
end
R.tab.antes_depois = html_tabela( ...
  {'Grandeza (°C)', sprintf('Antes: quadros %d–%d', cfg.antes), sprintf('Depois: quadros %d–%d', cfg.depois), 'Variação (°C)', 'Variação (%)'}, ...
  linhas, 'Médias de cada janela de 10 quadros.');
escrever_csv(fullfile(pasta_saida, 'lote2_antes_depois.csv'), {'grandeza', 'antes_C', 'depois_C', 'variacao_C', 'variacao_pct'}, r2, csv);

mp = L2.quadro >= cfg.fases(2).ini & L2.quadro <= cfg.fases(2).fim;
Tp = tendencia_linear(L2.quadro(mp), L2.tmed(mp));
R.val.pat_subida = fmt(Tp.b * (cfg.fases(2).fim - cfg.fases(2).ini), 2, true);
R.val.dd_tmax = fmt(dd.tmax, 2, true);
R.val.dd_tmin = fmt(dd.tmin, 2, true);
R.val.dd_tmed = fmt(dd.tmed, 2, true);
R.val.dd_dp   = fmt(dd.dp, 2, true);
R.val.dd_dp_pct  = fmt(dp_.dp, 0, true);
R.val.dd_amp     = fmt(dd.amp, 2, true);
R.val.dd_amp_pct = fmt(dp_.amp, 0, true);
R.val.aq_amp  = [fmt(L2.amp(1), 1) ' para ' fmt(median(L2.amp(mp)), 1)];
R.val.n2      = sprintf('%d', numel(L2.quadro));
R.val.q2_ini  = sprintf('%d', L2.quadro(1));
R.val.q2_fim  = sprintf('%d', L2.quadro(end));

% Figura — séries do lote 2 com fases
h = fig_nova(8, 3.4);
sombrear_faixas(cfg.fases, [20.8 28.2], C);
hold on;
hl = [plot(L2.quadro, L2.tmax, 'color', C.lab), plot(L2.quadro, L2.tmed, 'color', C.pro), plot(L2.quadro, L2.tmin, 'color', C.c3)];
hold off;
xlim([L2.quadro(1) L2.quadro(end)]);
legend(hl, {'Máxima', 'Média', 'Mínima'}, 'location', 'east', 'box', 'off');
eixo_estilo(gca, 'Quadro (número do arquivo)', 'Temperatura (°C)', 'Lote 2 — emissão externa e evento climático');
fig_salvar(h, fullfile(pasta_saida, 'lote2_series.png'));
R.fig.lote2_series = 'lote2_series.png';

% Figura — contraste espacial do lote 2
h = fig_nova(8, 4.2);
subplot(2, 1, 1);
sombrear_faixas(cfg.fases, [0.35 0.8], C, false);
hold on; plot(L2.quadro, L2.dp, 'color', C.pro); hold off;
xlim([L2.quadro(1) L2.quadro(end)]);
eixo_estilo(gca, '', 'DP espacial (°C)', 'Desvio-padrão dentro do quadro');
subplot(2, 1, 2);
sombrear_faixas(cfg.fases, [3 5.4], C, false);
hold on; plot(L2.quadro, L2.amp, 'color', C.pro); hold off;
xlim([L2.quadro(1) L2.quadro(end)]);
eixo_estilo(gca, 'Quadro (número do arquivo)', 'Amplitude (°C)', 'Amplitude (máxima − mínima) dentro do quadro');
fig_salvar(h, fullfile(pasta_saida, 'lote2_contraste.png'));
R.fig.lote2_contraste = 'lote2_contraste.png';

% ================================================== Para o índice ==========
R.resumo = ['Câmera dentro da cabine fechada, sem fonte de IR (lote 1), e com emissão externa ' ...
            'durante um evento climático (lote 2).'];
R.destaques = { ...
  'Deriva da média, lote 1',        [fmt(delta.tmed, 2, true) ' °C'];
  'Inclinação no trecho final',     [fmt(tfin.tmed.b, 4) ' °C/quadro'];
  'Amplitude após a perturbação',   [fmt(dp_.amp, 0, true) '%']};

printf('Lote 1: Tmed %+.2f °C (Tmax %+.2f, Tmin %+.2f); trecho final %.4f [%.4f; %.4f] °C/quadro\n', ...
       delta.tmed, delta.tmax, delta.tmin, tfin.tmed.b, tfin.tmed.ic);
printf('Lote 2 (depois - antes): Tmax %+.2f, Tmin %+.2f, DP %+.2f, Amp %+.2f °C\n', dd.tmax, dd.tmin, dd.dp, dd.amp);
