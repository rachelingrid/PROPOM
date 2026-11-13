function f = relatorio_ambiental(info, get, amb, M, P)
% Relatório parcial ambiental: checagem inicial, série do termo-higrômetro
% em torno da coleta (com as faixas aceitáveis e o instante de cada imagem)
% e UR/temperatura no momento de cada imagem.
% amb: struct array (ordem, condicao, t, UR, T, status) de processar_coleta.

  [f, ax, txt, y] = relatorio_base('Relatório parcial ambiental', info);

  % ---------- checagem inicial ----------
  y = secao_relatorio(txt, ax, y, 'Checagem inicial (antes da aclimatação)');
  ur0 = str2double(get('UR_checagem_pct')); t0 = str2double(get('T_checagem_C'));
  txt(0.08, y, sprintf('UR = %.1f %%  (faixa %g–%g %%)   |   Temperatura do protótipo = %.2f °C  (faixa %g–%g °C)', ...
      ur0, P.UR_faixa_pct, t0, P.T_faixa_C), 'fontsize', 9.5);
  y = y - 0.019;
  txt(0.08, y, sprintf('Origem: %s   |   Hora: %s', get('checagem_origem'), get('checagem_hora')), ...
      'fontsize', 8.5, 'color', [.3 .3 .3]);
  y = y - 0.04;

  % ---------- gráficos ----------
  y = secao_relatorio(txt, ax, y, 'Termo-higrômetro durante a coleta');
  tc = [amb.t];
  if isempty(M.t)
    txt(0.08, y, 'Sem dados do termo-higrômetro na pasta TEMUR.', 'fontsize', 9.5, 'color', [.7 0 0]);
    y = y - 0.04;
  else
    ini = min(tc) - 15/1440; fim = max(tc) + 15/1440;
    s = M.t >= ini & M.t <= fim;
    x = (M.t(s) - min(tc)) * 1440;
    xc = (tc - min(tc)) * 1440;
    xl = [(ini - min(tc))*1440, (fim - min(tc))*1440];
    graf = {M.UR(s), P.UR_faixa_pct, 'UR (%)', [0.1 0.665 0.82 0.095]; ...
            M.T(s),  P.T_faixa_C,    'T (°C)', [0.1 0.535 0.82 0.095]};
    for g = 1:2
      axes('position', graf{g,4}); hold on; box on;
      fx = graf{g,2};
      fill([xl(1) xl(2) xl(2) xl(1)], [fx(1) fx(1) fx(2) fx(2)], [0.88 0.95 0.88], 'edgecolor', 'none');
      yv = graf{g,1};
      lim = [min([yv(:); fx(1)]) max([yv(:); fx(2)])]; lim = lim + [-1 1] * 0.08 * diff(lim);
      for k = 1:numel(amb)
        cor = [0.2 0.45 0.85]; if ~isempty(strfind(amb(k).condicao, 'fechado')), cor = [0.85 0.3 0.2]; end
        plot([xc(k) xc(k)], lim, '-', 'color', cor, 'linewidth', 0.6);
      end
      plot(x, yv, 'k.-', 'markersize', 8, 'linewidth', 0.8);
      xlim(xl); ylim(lim); ylabel(graf{g,3}, 'fontsize', 9); set(gca, 'fontsize', 8);
      if g == 2
        xlabel(sprintf('minutos em relação à 1ª imagem (%s)', datestr(min(tc), 'HH:MM:SS')), 'fontsize', 8.5);
      end
    end
    axes(ax);
    txt(0.1, 0.488, 'Faixa verde = aceitável   |   linhas azuis = olhos abertos   |   linhas vermelhas = olhos fechados', ...
        'fontsize', 8, 'color', [.3 .3 .3]);
    y = 0.46;
  end

  % ---------- tabela por imagem ----------
  y = secao_relatorio(txt, ax, y, 'Valores no momento de cada imagem');
  cx = [0.08 0.15 0.33 0.47 0.6 0.74];
  cabs = {'Nº', 'Condição', 'Hora', 'UR (%)', 'T (°C)', 'Situação'};
  for k = 1:6, txt(cx(k), y, cabs{k}, 'fontsize', 9, 'fontweight', 'bold'); end
  nmax = min(numel(amb), 12);
  for k = 1:nmax
    y = y - 0.0165;
    fora = isfinite(amb(k).UR) && (amb(k).UR < P.UR_faixa_pct(1) || amb(k).UR > P.UR_faixa_pct(2) || ...
           amb(k).T < P.T_faixa_C(1) || amb(k).T > P.T_faixa_C(2));
    st = amb(k).status; if strcmp(st, 'ok'), st = 'na faixa'; end
    if fora, st = 'FORA DA FAIXA'; end
    cor = [0 0 0]; if fora || ~isfinite(amb(k).UR), cor = [0.75 0 0]; end
    vals = {sprintf('%d', amb(k).ordem), amb(k).condicao, datestr(amb(k).t, 'HH:MM:SS'), ...
            num_txt(amb(k).UR, 1), num_txt(amb(k).T, 2), st};
    for c = 1:6, txt(cx(c), y, vals{c}, 'fontsize', 8.5, 'color', cor); end
  end
  if numel(amb) > nmax
    y = y - 0.0175; txt(0.08, y, sprintf('(+ %d imagens na tabela ambiente_por_imagem.csv)', numel(amb) - nmax), 'fontsize', 8);
  end

  % ---------- resumo ----------
  y = y - 0.03;
  y = secao_relatorio(txt, ax, y, 'Resumo');
  txt(0.08, y, sprintf('Momento da coleta (1ª imagem, %s):  UR = %s %%  |  T = %s °C', ...
      datestr(amb(1).t, 'HH:MM:SS'), num_txt(amb(1).UR, 1), num_txt(amb(1).T, 2)), 'fontsize', 9.5);
  for c = {'aberto', 'fechado'}
    y = y - 0.019;
    s = strcmp({amb.condicao}, c{1});
    u = [amb(s).UR]; t = [amb(s).T];
    txt(0.08, y, sprintf('Olhos %ss (n = %d):  UR = %s %%  |  T = %s °C', c{1}, sum(s), ...
        ms(u, 1), ms(t, 2)), 'fontsize', 9.5);
  end

  met = 'média da leitura anterior e da posterior ao horário da imagem';
  if strcmp(P.temur_metodo, 'linear'), met = 'interpolação linear entre a leitura anterior e a posterior'; end
  rodape_relatorio(txt, ax, { ...
    sprintf('UR e temperatura no momento de cada imagem: %s (arquivos da pasta TEMUR).', met), ...
    sprintf('Sem leitura posterior, ou com leituras vizinhas a mais de %g min, o valor fica em branco (não há extrapolação).', ...
            P.temur_intervalo_max_min), ...
    'Horário das imagens = relógio do computador da coleta; mantenha-o sincronizado com o celular do termo-higrômetro.'});
end

function s = num_txt(x, d)
  if isfinite(x), s = sprintf(['%.' num2str(d) 'f'], x); else, s = '—'; end
end

function s = ms(x, d)
  x = x(isfinite(x));
  if isempty(x), s = '—'; return; end
  s = sprintf(['%.' num2str(d) 'f ± %.' num2str(d) 'f'], mean(x), std(x));
end
