% ANALISE  Experimento 02 — Estabilidade de temperatura e umidade: laboratório x cabine
%
%   Dois registradores (1 amostra/min): LAB no laboratório e PRO dentro da cabine (protótipo).
%   Janelas de 48 h com o ar-condicionado em regimes diferentes são recortadas dos dados brutos.
%
%   Perguntas:
%     1. Quanto da oscilação ambiental (sobretudo a imposta pelo ciclo do compressor) a cabine atenua?
%     2. Os níveis e as dispersões de LAB e PRO diferem?  (Wilcoxon pareado e Brown-Forsythe)

% ============================ CONFIGURAÇÃO ================================
% Para incluir um novo cenário, acrescente uma entrada aqui (sigla, nome, início).
cfg.cenarios = struct( ...
  'sigla',  {'SAR', 'DRY', 'COL', 'AR'}, ...
  'nome',   {'Sem ar-condicionado', 'Ar-condicionado em modo DRY', ...
             'Ar-condicionado em modo COOL', 'Ar-condicionado ligado (modo não definido)'}, ...
  'inicio', {'2026-06-03 19:00', '2026-05-16 19:00', '2026-06-13 19:00', '2026-05-30 19:00'});
cfg.duracao_min = 2880;      % 48 h
cfg.banda_min   = [10 120];  % faixa de períodos atribuída ao ciclo do compressor (min)
cfg.nseg_min    = 1440;      % segmento do Welch: 24 h, janela de Hann, 50% de sobreposição

% Dessecante: sílica gel doméstica colocada dentro da cabine para reduzir e manter baixa a UR interna
cfg.dessecante   = '2026-06-09 19:32';   % instante da introdução (degrau visível no registro do PRO)
cfg.des_ajuste_h = 48;                   % horas após a introdução usadas no ajuste exponencial
cfg.des_plato_h  = [36 48];              % intervalo (h após a introdução) usado como nível alcançado
% ==========================================================================

C = cores_propom();
[tl, Tl, Ul] = ler_serie_csv(fullfile('dados', 'LAB_bruto.csv'));
[tp, Tp, Up] = ler_serie_csv(fullfile('dados', 'PRO_bruto.csv'));
printf('LAB: %d amostras, %s a %s\n', numel(tl), datestr(tl(1), 'dd/mm/yyyy HH:MM'), datestr(tl(end), 'dd/mm/yyyy HH:MM'));
printf('PRO: %d amostras, %s a %s\n', numel(tp), datestr(tp(1), 'dd/mm/yyyy HH:MM'), datestr(tp(end), 'dd/mm/yyyy HH:MM'));
R.val.integridade = [descrever_integridade('LAB', tl) ' ' descrever_integridade('PRO', tp)];

nc = numel(cfg.cenarios);
gv = {'T', 'UR'};  gnome = {'Temperatura', 'Umidade relativa'};  gun = {'°C', '%'};
res = struct();
for s = 1:nc
  cen = cfg.cenarios(s);
  [lT, lU, th] = recortar_janela(tl, Tl, Ul, cen.inicio, cfg.duracao_min);
  [pT, pU]     = recortar_janela(tp, Tp, Up, cen.inicio, cfg.duracao_min);
  serie.(cen.sigla) = struct('th', th, 'LAB_T', lT, 'PRO_T', pT, 'LAB_UR', lU, 'PRO_UR', pU);
  for v = 1:2
    a = serie.(cen.sigla).(['LAB_' gv{v}]);
    b = serie.(cen.sigla).(['PRO_' gv{v}]);
    r = struct();
    r.n = numel(a);
    r.media = [mean(a) mean(b)];
    r.dp    = [std(a) std(b)];
    r.cv    = 100 * r.dp ./ r.media;
    r.amp   = [max(a) - min(a), max(b) - min(b)];
    r.dif_mediana = median(b - a);
    r.W   = wilcoxon_pareado(b, a);            % d = PRO - LAB
    r.Lev = levene_bf(a, b);
    [Pa, f] = psd_welch(a, 1, cfg.nseg_min);
    [Pb, ~] = psd_welch(b, 1, cfg.nseg_min);
    [pa, pka] = potencia_banda(Pa, f, cfg.banda_min);
    [pb, pkb] = potencia_banda(Pb, f, cfg.banda_min);
    r.rms  = sqrt([pa pb]);
    r.pico = [pka pkb];
    r.aten = 100 * (1 - sqrt(pb / pa));
    r.psd  = struct('f', f, 'LAB', Pa, 'PRO', Pb);
    [r.ciclo, r.ciclo_ac] = periodo_autocorr(a, 121, cfg.banda_min);   % ciclo rapido no LAB, dominio do tempo
    [r.sw_W(1), r.sw_p(1)] = shapiro_wilk(a);
    [r.sw_W(2), r.sw_p(2)] = shapiro_wilk(b);
    res.(cen.sigla).(gv{v}) = r;
    printf('%-4s %-3s  DP LAB %.3f PRO %.3f | RMS banda LAB %.3f PRO %.3f | aten %.0f%% | pico LAB %.0f min | ciclo AC %g min | r=%.3f r_rb=%.3f n_ef=%.0f p_aj=%.3g\n', ...
           cen.sigla, gv{v}, r.dp, r.rms, r.aten, pka, r.ciclo, r.W.r, r.W.r_rb, r.W.n_ef, r.W.p_aj);
  end
end

% ============================================================ DESSECANTE ==
td  = datenum(cfg.dessecante, 'yyyy-mm-dd HH:MM');
i0  = find(round(tp * 1440) == round(td * 1440));
th_p = (tp - td) * 24;                         % horas desde a introdução (PRO)
th_l = (tl - td) * 24;                         % idem (LAB)
UAp = umidade_absoluta(Tp, Up);   UAl = umidade_absoluta(Tl, Ul);
m_antes = th_p >= -6 & th_p < 0;
m_plato = th_p >= cfg.des_plato_h(1) & th_p < cfg.des_plato_h(2);
m_plab  = th_l >= cfg.des_plato_h(1) & th_l < cfg.des_plato_h(2);
m_aj    = th_p >= 1/60 & th_p <= cfg.des_ajuste_h;
Ed = ajuste_exponencial(th_p(m_aj), Up(m_aj));
des.ur_antes  = mean(Up(m_antes));   des.ua_antes = mean(UAp(m_antes));   des.t_antes = mean(Tp(m_antes));
des.ur_plato  = mean(Up(m_plato));   des.ua_plato = mean(UAp(m_plato));   des.t_plato = mean(Tp(m_plato));
des.degrau    = mean(Up(i0:i0+9)) - Up(i0 - 1);
des.ur_fim    = mean(Up(th_p > th_p(end) - 6));
des.ua_lab    = mean(UAl(m_plab));   des.ur_lab = mean(Ul(m_plab));
printf('Dessecante: UR %.1f -> %.1f %% (degrau %.1f; tau %.1f h; UR_inf %.1f); UA %.1f -> %.1f g/m3; LAB UA %.1f\n', ...
       des.ur_antes, des.ur_plato, des.degrau, Ed.tau, Ed.tinf, des.ua_antes, des.ua_plato, des.ua_lab);

R.val.des_data    = datestr(td, 'dd/mm/yyyy, HH:MM');
R.val.des_ur_antes = fmt(des.ur_antes, 1);
R.val.des_ur_plato = fmt(des.ur_plato, 1);
R.val.des_degrau  = fmt(des.degrau, 1, true);
R.val.des_tau     = fmt(Ed.tau, 1);
R.val.des_urinf   = fmt(Ed.tinf, 1);
R.val.des_r2      = fmt(Ed.r2, 3);
R.val.des_aj_h    = sprintf('%d', cfg.des_ajuste_h);
R.val.des_plato   = sprintf('%d–%d h', cfg.des_plato_h);
R.val.des_ua_antes = fmt(des.ua_antes, 1);
R.val.des_ua_plato = fmt(des.ua_plato, 1);
R.val.des_ua_pct  = fmt(100 * (des.ua_plato - des.ua_antes) / des.ua_antes, 0, true);
R.val.des_t_antes = fmt(des.t_antes, 1);
R.val.des_t_plato = fmt(des.t_plato, 1);
R.val.des_ua_lab  = fmt(des.ua_lab, 1);
R.val.des_ur_lab  = fmt(des.ur_lab, 1);
R.val.des_ur_fim  = fmt(des.ur_fim, 1);
R.val.des_fim_data = datestr(tp(end), 'dd/mm');

R.tab.dessecante = html_tabela( ...
  {'Grandeza (PRO, dentro da cabine)', '6 h antes', sprintf('%d–%d h depois', cfg.des_plato_h), 'Variação'}, ...
  {'Umidade relativa (%)', fmt(des.ur_antes, 1), fmt(des.ur_plato, 1), fmt(des.ur_plato - des.ur_antes, 1, true); ...
   'Umidade absoluta (g/m³)', fmt(des.ua_antes, 1), fmt(des.ua_plato, 1), fmt(des.ua_plato - des.ua_antes, 1, true); ...
   'Temperatura (°C)', fmt(des.t_antes, 1), fmt(des.t_plato, 1), fmt(des.t_plato - des.t_antes, 1, true)}, ...
  'Umidade absoluta pela fórmula de Magnus (coeficientes WMO), a partir da temperatura e da UR de cada minuto.');

% ================================================================ TABELAS ==
rotc = @(s) sprintf('<span class="sigla">%s</span> %s', cfg.cenarios(s).sigla, cfg.cenarios(s).nome);
banda_txt = sprintf('%d–%d min', cfg.banda_min);

% 1) Estabilidade e atenuação
linhas = {};  csv = [];  rot_csv = {};
for v = 1:2
  for s = 1:nc
    r = res.(cfg.cenarios(s).sigla).(gv{v});
    linhas(end+1, :) = {[rotc(s) ' · ' gnome{v} ' (' gun{v} ')'], fmt(r.dp(1), 2), fmt(r.dp(2), 2), fmt(r.dp(2) / r.dp(1), 2), ...
                        fmt(r.rms(1), 3), fmt(r.rms(2), 3), ['<strong>' fmt(r.aten, 0) '%</strong>'], fmt(r.pico(1), 0), fmt(r.ciclo, 0)}; %#ok<SAGROW>
    csv(end+1, :) = [r.dp r.dp(2)/r.dp(1) r.rms r.aten r.pico r.ciclo]; %#ok<SAGROW>
    rot_csv{end+1} = [cfg.cenarios(s).sigla '_' gv{v}]; %#ok<SAGROW>
  end
end
R.tab.estabilidade = html_tabela( ...
  {'Cenário · grandeza', 'DP LAB', 'DP PRO', 'DP PRO / LAB', ['RMS na banda ' banda_txt ', LAB'], 'RMS na banda, PRO', ...
   'Atenuação da oscilação', 'Pico da DEP no LAB (min)', 'Ciclo pela autocorrelação no LAB (min)'}, linhas, ...
  sprintf(['RMS na banda = raiz da potência espectral (Welch, segmentos de %d min, Hann, 50%% de sobreposição, tendência removida) ' ...
           'integrada entre %d e %d min de período. Atenuação = 1 − RMS<sub>PRO</sub>/RMS<sub>LAB</sub>. ' ...
           'Ciclo pela autocorrelação = primeiro máximo da autocorrelação após remover a média móvel de 2 h (— = sem ciclo detectável).'], cfg.nseg_min, cfg.banda_min));
escrever_csv(fullfile(pasta_saida, 'estabilidade_por_cenario.csv'), ...
  {'cenario_grandeza', 'dp_lab', 'dp_pro', 'razao_dp', 'rms_banda_lab', 'rms_banda_pro', 'atenuacao_pct', 'periodo_pico_lab_min', 'periodo_pico_pro_min', 'ciclo_autocorr_lab_min'}, ...
  rot_csv, csv);

% 2) Nível: Wilcoxon pareado + Brown-Forsythe
linhas = {};  csv = [];
for v = 1:2
  for s = 1:nc
    r = res.(cfg.cenarios(s).sigla).(gv{v});  W = r.W;
    linhas(end+1, :) = {[rotc(s) ' · ' gnome{v}], fmt(r.media(1), 2), fmt(r.media(2), 2), fmt(r.dif_mediana, 2, true), ...
                        sprintf('%.1f', W.V), fmt(W.z, 1), fmt(W.r, 2), fmt(W.r_rb, 2), fmt(W.rho1, 3), fmt(W.n_ef, 0), ...
                        fmt_p(W.p), fmt_p(W.p_aj), fmt_p(r.Lev.p)}; %#ok<SAGROW>
    csv(end+1, :) = [r.media r.dif_mediana W.n W.V W.z W.r W.r_rb W.rho1 W.n_ef W.p W.p_aj r.Lev.F r.Lev.p]; %#ok<SAGROW>
  end
end
R.tab.nivel = html_tabela( ...
  {'Cenário · grandeza', 'Média LAB', 'Média PRO', 'Mediana PRO − LAB', 'V', 'z', 'r = z/√n', 'r rank-bisserial', ...
   'ρ₁ das diferenças', 'n efetivo', 'p', 'p ajustado', 'p Levene (B-F)'}, linhas, ...
  ['Wilcoxon de postos sinalizados pareado minuto a minuto (d = PRO − LAB; mesma convenção do <code>wilcox.test</code> do R). ' ...
   'p ajustado: variância inflada pelo n efetivo, n(1 − ρ₁)/(1 + ρ₁). Levene centrado na mediana (Brown–Forsythe), ' ...
   'sem ajuste para autocorrelação.']);
escrever_csv(fullfile(pasta_saida, 'wilcoxon_levene_por_cenario.csv'), ...
  {'cenario_grandeza', 'media_lab', 'media_pro', 'mediana_pro_menos_lab', 'n', 'V', 'z', 'r', 'r_rank_bisserial', ...
   'rho1', 'n_efetivo', 'p', 'p_ajustado', 'levene_F', 'levene_p'}, rot_csv, csv);

% 3) Normalidade
linhas = {};
for v = 1:2
  for s = 1:nc
    r = res.(cfg.cenarios(s).sigla).(gv{v});
    for e = 1:2
      eq = {'LAB', 'PRO'};
      linhas(end+1, :) = {[cfg.cenarios(s).sigla ' · ' gnome{v} ' · ' eq{e}], fmt(r.sw_W(e), 4), fmt_p(r.sw_p(e))}; %#ok<SAGROW>
    end
  end
end
R.tab.normalidade = html_tabela({'Série', 'W de Shapiro–Wilk', 'p'}, linhas, ...
  'Algoritmo de Royston (1995). Resultados idênticos aos do R e do SciPy para as mesmas séries.');

% ================================================================ FIGURAS ==
% Visão geral dos registros completos
h = fig_nova(8, 4.8);
jan = struct('ini', {}, 'fim', {}, 'nome', {});
for s = 1:nc
  t0 = datenum(cfg.cenarios(s).inicio, 'yyyy-mm-dd HH:MM');
  jan(s) = struct('ini', t0, 'fim', t0 + cfg.duracao_min / 1440, 'nome', cfg.cenarios(s).sigla);
end
for v = 1:2
  subplot(2, 1, v);
  if v == 1
    yl = Tl;  yp = Tp;  yl_ = [floor(min([Tl; Tp])) - 0.5, ceil(max([Tl; Tp])) + 2];
  else
    yl = Ul;  yp = Up;  yl_ = [floor(min([Ul; Up])) - 2, ceil(max([Ul; Up])) + 7];
  end
  sombrear_faixas(jan, yl_, C, true, 0, false);
  hold on;
  [xa, ya] = quebrar_lacunas(tl, yl);  [xb, yb] = quebrar_lacunas(tp, yp);
  plot(xa, ya, 'color', C.lab, 'linewidth', 0.6);
  plot(xb, yb, 'color', C.pro, 'linewidth', 0.6);
  hold off;
  x1 = max(tl(end), tp(end));
  xlim([min(tl(1), tp(1)), x1 + 2.2]);
  datetick('x', 'dd/mm', 'keeplimits');
  % rótulos diretos no fim de cada série (identidade sem depender só da cor)
  ya_ = yl(end);  yb_ = yp(end);  sep = 0.09 * diff(yl_);
  if abs(ya_ - yb_) < sep                     % afasta os rótulos se as séries terminam juntas
    m_ = (ya_ + yb_) / 2;  ya_ = m_ + sep / 2 * sign(ya_ - yb_ + eps);  yb_ = m_ - sep / 2 * sign(ya_ - yb_ + eps);
  end
  text(tl(end) + 0.3, ya_, 'LAB', 'color', C.lab, 'fontweight', 'bold', 'verticalalignment', 'middle');
  text(tp(end) + 0.3, yb_, 'PRO', 'color', C.pro, 'fontweight', 'bold', 'verticalalignment', 'middle');
  if v == 2                                    % marca a introdução do dessecante
    hold on;  plot([td td], yl_, ':', 'color', C.sec, 'linewidth', 1);  hold off;
    text(td + 0.3, yl_(1) + 0.08 * diff(yl_), 'sílica gel', 'color', C.sec, 'fontsize', 8);
  end
  if v == 1
    eixo_estilo(gca, '', 'Temperatura (°C)', 'Registro completo — LAB (laboratório) e PRO (cabine); janelas de 48 h sombreadas');
  else
    eixo_estilo(gca, 'Data (2026)', 'Umidade relativa (%)', '');
  end
end
fig_salvar(h, fullfile(pasta_saida, 'visao_geral.png'));
R.fig.visao_geral = 'visao_geral.png';

% Introdução do dessecante
h = fig_nova(8, 4.6);
xl_ = [-24 96];
for v = 1:2
  subplot(2, 1, v);
  if v == 1, ya = Ul; yb = Up; rot = 'Umidade relativa (%)'; else, ya = UAl; yb = UAp; rot = 'Umidade absoluta (g/m³)'; end
  mlv = th_l >= xl_(1) & th_l <= xl_(2);  mpv = th_p >= xl_(1) & th_p <= xl_(2);
  [xa, ya2] = quebrar_lacunas(tl(mlv), ya(mlv));  xa = (xa - td) * 24;
  hold on;
  hl = [plot(xa, ya2, 'color', C.lab, 'linewidth', 0.6), plot(th_p(mpv), yb(mpv), 'color', C.pro, 'linewidth', 1)];
  if v == 1
    plot(th_p(m_aj), Ed.yhat, '--', 'color', C.ajuste, 'linewidth', 1);
  end
  yl_ = get(gca, 'ylim');
  plot([0 0], yl_, ':', 'color', C.sec, 'linewidth', 1);
  hold off;
  ylim(yl_);  xlim(xl_);  set(gca, 'xtick', -24:12:96);
  if v == 1
    text(1.5, yl_(2) - 0.06 * diff(yl_), 'sílica gel colocada na cabine', 'color', C.sec, 'fontsize', 8, 'verticalalignment', 'top');
    legend(hl, {'LAB', 'PRO'}, 'location', 'southwest', 'box', 'off', 'orientation', 'horizontal');
    eixo_estilo(gca, '', rot, sprintf('Dessecante na cabine — %s', datestr(td, 'dd/mm/yyyy HH:MM')));
  else
    eixo_estilo(gca, 'Horas desde a introdução do dessecante', rot, '');
  end
end
fig_salvar(h, fullfile(pasta_saida, 'dessecante.png'));
R.fig.dessecante = 'dessecante.png';

% Por cenário: séries e espectros
for s = 1:nc
  sg = cfg.cenarios(s).sigla;  S = serie.(sg);
  h = fig_nova(8, 4.4);
  for v = 1:2
    subplot(2, 1, v);
    hold on;
    hl = [plot(S.th, S.(['LAB_' gv{v}]), 'color', C.lab, 'linewidth', 0.8), ...
          plot(S.th, S.(['PRO_' gv{v}]), 'color', C.pro, 'linewidth', 0.8)];
    hold off;
    xlim([0 48]);  set(gca, 'xtick', 0:6:48);
    if v == 1
      legend(hl, {'LAB', 'PRO'}, 'location', 'northeast', 'box', 'off', 'orientation', 'horizontal');
      eixo_estilo(gca, '', 'Temperatura (°C)', sprintf('%s — %s', sg, cfg.cenarios(s).nome));
    else
      eixo_estilo(gca, sprintf('Horas desde %s', datestr(datenum(cfg.cenarios(s).inicio, 'yyyy-mm-dd HH:MM'), 'dd/mm/yyyy HH:MM')), ...
                  'Umidade relativa (%)', '');
    end
  end
  fig_salvar(h, fullfile(pasta_saida, ['serie_' sg '.png']));
  R.fig.(['serie_' sg]) = ['serie_' sg '.png'];

  h = fig_nova(8, 3.2);
  for v = 1:2
    subplot(1, 2, v);
    r = res.(sg).(gv{v});  per = 1 ./ r.psd.f(2:end);
    yy = [r.psd.LAB(2:end); r.psd.PRO(2:end)];
    yl_ = [10^floor(log10(min(yy(yy > 0)))) 10^ceil(log10(max(yy)))];
    sombrear_faixas(struct('ini', cfg.banda_min(1), 'fim', cfg.banda_min(2), 'nome', 'banda'), yl_, C, false, 0, false);
    hold on;
    hl = [loglog(per, r.psd.LAB(2:end), 'color', C.lab, 'linewidth', 1), loglog(per, r.psd.PRO(2:end), 'color', C.pro, 'linewidth', 1)];
    hold off;
    set(gca, 'xscale', 'log', 'yscale', 'log', 'xdir', 'reverse', 'xtick', [10 20 60 120 360 1440], ...
        'xticklabel', {'10', '20', '60', '120', '360', '1440'});
    xlim([8 1440]);  ylim(yl_);
    if v == 1, legend(hl, {'LAB', 'PRO'}, 'location', 'southwest', 'box', 'off'); end
    eixo_estilo(gca, 'Período (min)', sprintf('DEP (%s²·min)', gun{v}), sprintf('%s — %s', sg, gnome{v}));
  end
  fig_salvar(h, fullfile(pasta_saida, ['espectro_' sg '.png']));
  R.fig.(['espectro_' sg]) = ['espectro_' sg '.png'];
end

% Resumo: RMS na banda do compressor, por cenário
h = fig_nova(8, 3.2);
for v = 1:2
  subplot(1, 2, v);
  M = zeros(nc, 2);
  for s = 1:nc, M(s, :) = res.(cfg.cenarios(s).sigla).(gv{v}).rms; end
  hb = bar(M, 'grouped', 'basevalue', 1e-3);
  set(hb(1), 'facecolor', C.lab, 'edgecolor', 'none');
  set(hb(2), 'facecolor', C.pro, 'edgecolor', 'none');
  set(gca, 'yscale', 'log', 'xticklabel', {cfg.cenarios.sigla});
  ylim([10^floor(log10(min(M(:)))) 10^ceil(log10(max(M(:))))]);
  if v == 1, legend(hb, {'LAB', 'PRO'}, 'location', 'northwest', 'box', 'off'); end
  eixo_estilo(gca, '', sprintf('RMS na banda (%s)', gun{v}), sprintf('%s — %s', gnome{v}, banda_txt));
end
fig_salvar(h, fullfile(pasta_saida, 'banda_resumo.png'));
R.fig.banda_resumo = 'banda_resumo.png';

% ======================================================= VALORES DO TEXTO ==
u = @(sg) res.(sg).UR;  t = @(sg) res.(sg).T;
R.val.banda       = banda_txt;
R.val.nseg        = sprintf('%d', cfg.nseg_min);
R.val.ur_rms_sar  = fmt(u('SAR').rms(1), 3);
R.val.ur_rms_dry  = fmt(u('DRY').rms(1), 2);
R.val.ur_rms_col  = fmt(u('COL').rms(1), 2);
R.val.ur_rms_ar   = fmt(u('AR').rms(1), 2);
R.val.ur_x_dry    = fmt(u('DRY').rms(1) / u('SAR').rms(1), 0);
R.val.ur_x_col    = fmt(u('COL').rms(1) / u('SAR').rms(1), 0);
R.val.ur_aten_dry = fmt(u('DRY').aten, 0);
R.val.ur_aten_col = fmt(u('COL').aten, 0);
R.val.ur_aten_ar  = fmt(u('AR').aten, 0);
R.val.ur_aten_sar = fmt(u('SAR').aten, 0);
R.val.t_aten_dry  = fmt(t('DRY').aten, 0);
R.val.t_aten_col  = fmt(t('COL').aten, 0);
R.val.t_aten_ar   = fmt(t('AR').aten, 0);
R.val.t_aten_sar  = fmt(t('SAR').aten, 0);
R.val.pico_dry    = fmt(u('DRY').pico(1), 0);
R.val.pico_col    = fmt(u('COL').pico(1), 0);
R.val.pico_ar     = fmt(u('AR').pico(1), 0);
R.val.ciclo_dry   = fmt(u('DRY').ciclo, 0);
R.val.ciclo_col   = fmt(u('COL').ciclo, 0);
R.val.ciclo_ar    = fmt(u('AR').ciclo, 0);
R.val.dp_ur_pro_min = fmt(min(cellfun(@(sg) u(sg).dp(2), {cfg.cenarios.sigla})), 2);
R.val.dp_ur_pro_max = fmt(max(cellfun(@(sg) u(sg).dp(2), {cfg.cenarios.sigla})), 2);
R.val.col_dif_ur  = fmt(u('COL').dif_mediana, 1, true);
R.val.dry_T_lab   = fmt(t('DRY').dp(1), 2);
R.val.col_T_lab   = fmt(t('COL').dp(1), 2);
R.val.dry_U_lab   = fmt(u('DRY').dp(1), 2);
R.val.col_U_lab   = fmt(u('COL').dp(1), 2);
R.val.dry_T_rms   = fmt(t('DRY').rms(1), 3);
R.val.col_T_rms   = fmt(t('COL').rms(1), 3);
R.val.n_ef_min    = fmt(min(cellfun(@(sg) min(res.(sg).T.W.n_ef, res.(sg).UR.W.n_ef), {cfg.cenarios.sigla})), 0);
R.val.n_ef_max    = fmt(max(cellfun(@(sg) max(res.(sg).T.W.n_ef, res.(sg).UR.W.n_ef), {cfg.cenarios.sigla})), 0);
R.val.n_jan       = sprintf('%d', cfg.duracao_min + 1);
sig = {cfg.cenarios.sigla};  com_ar = sig(~strcmp(sig, 'SAR'));
R.val.ur_rms_pro_min = fmt(min(cellfun(@(sg) u(sg).rms(2), com_ar)), 2);
R.val.ur_rms_pro_max = fmt(max(cellfun(@(sg) u(sg).rms(2), com_ar)), 2);
rhos = cellfun(@(sg) [res.(sg).T.W.rho1 res.(sg).UR.W.rho1], sig, 'uniformoutput', false);  rhos = [rhos{:}];
R.val.rho_min = fmt(min(rhos), 2);
R.val.rho_max = fmt(max(rhos), 2);
R.val.periodo     = [datestr(min(tl(1), tp(1)), 'dd/mm') ' a ' datestr(max(tl(end), tp(end)), 'dd/mm/yyyy')];

R.resumo = ['Registradores de temperatura e umidade no laboratório e dentro da cabine, em quatro regimes ' ...
            'do ar-condicionado: o ciclo do compressor e o quanto a cabine o atenua.'];
R.destaques = { ...
  'Oscilação de UR no LAB, DRY × sem ar', [fmt(u('DRY').rms(1) / u('SAR').rms(1), 0) '×'];
  'Atenuação da UR pela cabine (DRY)',     [fmt(u('DRY').aten, 0) '%'];
  'Atenuação da temperatura (DRY)',        [fmt(t('DRY').aten, 0) '%']};
