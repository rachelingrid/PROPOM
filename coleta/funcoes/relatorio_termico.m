function f = relatorio_termico(info, pasta_imagens, pasta_termico, P)
% Relatório parcial de dados térmicos: imagens em tons de cinza com a ROI
% marcada (1ª de olhos abertos e 1ª de olhos fechados) e, para OD e OE, as
% sete medidas resumidas sobre as 5 ROIs de cada condição
% (média ± desvio padrão entre as imagens). Tomadas extras não entram.

  [cab, lin] = ler_csv_texto(fullfile(pasta_termico, 'resultados_individuais.csv'));
  col = @(n) lin(:, strcmp(cab, n));
  cond = col('condicao_protocolo'); olho = col('olho'); arq = col('arquivo');

  med   = {'maximo','minimo','media','mediana','desvio_padrao','variancia','amplitude'};
  rotul = {'Máximo (°C)','Mínimo (°C)','Média (°C)','Mediana (°C)', ...
           'Desvio padrão (°C)','Variância (°C²)','Amplitude (°C)'};

  [f, ax, txt, y] = relatorio_base('Relatório parcial de dados térmicos', info);

  % ---------- imagens ----------
  conds = {'aberto', 'Olhos abertos'; 'fechado', 'Olhos fechados'};
  for c = 1:2
    i1 = find(strcmp(cond, conds{c,1}), 1);
    if isempty(i1), continue; end
    a = arq{i1}; [~, b] = fileparts(a);
    T = ler_matriz_termica(fullfile(pasta_imagens, a), P);
    S = load(fullfile(pasta_termico, 'mascaras', [b '.mat']));
    [r, k] = find(S.visor); m = 4;
    r0 = max(1, min(r)-m); r1 = min(size(T,1), max(r)+m);
    k0 = max(1, min(k)-m); k1 = min(size(T,2), max(k)+m);
    axes('position', [0.06 + (c-1)*0.46, 0.64, 0.42, 0.2]);
    sub = T(r0:r1, k0:k1); v = T(S.visor);
    matriz_vetorial(sub, [prctile_s(v, 10) prctile_s(v, 99.9)]); hold on;
    for id = {'OD', 'OE'}
      w = S.(['janela_' id{1}]);
      if any(~isfinite(w)), continue; end
      pos = [w(2)-1.5-k0+1, w(1)-1.5-r0+1, 3, 3];
      rectangle('position', pos, 'edgecolor', 'k', 'linewidth', 2.5);
      rectangle('position', pos, 'edgecolor', 'w', 'linewidth', 1);
      text(pos(1)+1.5, pos(2)-3, id{1}, 'color', 'w', 'fontweight', 'bold', ...
           'horizontalalignment', 'center', 'fontsize', 9, 'backgroundcolor', 'k', 'margin', 1);
    end
    title(sprintf('%s — %s', conds{c,2}, b), 'interpreter', 'none', 'fontsize', 9);
  end
  txt(0.5, 0.625, 'Participante de frente para a câmera: o olho direito (OD) aparece à esquerda da imagem.', ...
      'fontsize', 8, 'horizontalalignment', 'center', 'color', [.3 .3 .3]);

  % ---------- tabelas ----------
  axes(ax);
  y = 0.585;
  nomes = struct('OD', 'OD — olho direito', 'OE', 'OE — olho esquerdo');
  for id = {'OD', 'OE'}
    o = id{1};
    nA = sum(strcmp(cond, 'aberto') & strcmp(olho, o));
    nF = sum(strcmp(cond, 'fechado') & strcmp(olho, o));
    y = secao_relatorio(txt, ax, y, nomes.(o));
    txt(0.08, y, 'Medida (ROI 3×3)', 'fontsize', 9.5, 'fontweight', 'bold');
    txt(0.42, y, sprintf('Olhos abertos (n = %d)', nA), 'fontsize', 9.5, 'fontweight', 'bold');
    txt(0.70, y, sprintf('Olhos fechados (n = %d)', nF), 'fontsize', 9.5, 'fontweight', 'bold');
    for q = 1:numel(med)
      y = y - 0.021;
      x = str2double(col(med{q}));
      xa = x(strcmp(cond, 'aberto')  & strcmp(olho, o));
      xf = x(strcmp(cond, 'fechado') & strcmp(olho, o));
      dec = 2; if any(strcmp(med{q}, {'desvio_padrao','variancia'})), dec = 3; end
      txt(0.08, y, rotul{q}, 'fontsize', 9.5);
      txt(0.42, y, fmt(xa, dec), 'fontsize', 9.5);
      txt(0.70, y, fmt(xf, dec), 'fontsize', 9.5);
    end
    y = y - 0.045;
  end

  rodape_relatorio(txt, ax, { ...
    'Cada valor é a média ± desvio padrão das ROIs da condição. Em cada imagem, a ROI é a janela de 3 × 3 pixels com maior', ...
    'temperatura média no quadrante superior medial da região orbital; as sete medidas são calculadas nos nove pixels', ...
    'originais dessa janela (desvio padrão e variância amostrais, n − 1). Câmera UNI-T UTi320E, distância fixa de 50 cm.'});
end

function matriz_vetorial(M, lim)
% Matriz em tons de cinza como um polígono por pixel (vetorial), para o
% PDF não depender da exportação de imagens raster.
  [nl, nc] = size(M);
  [X, Y] = meshgrid(0.5:nc+0.5, 0.5:nl+0.5);
  V = [X(:) Y(:)];
  id = @(i, j) (j-1)*(nl+1) + i;
  [J, I] = meshgrid(1:nc, 1:nl);
  F = [id(I(:), J(:)), id(I(:), J(:)+1), id(I(:)+1, J(:)+1), id(I(:)+1, J(:))];
  g = (M(:) - lim(1)) / (lim(2) - lim(1)); g = min(max(g, 0), 1);
  patch('faces', F, 'vertices', V, 'facevertexcdata', [g g g], ...
        'facecolor', 'flat', 'edgecolor', 'flat', 'linewidth', 0.3);
  set(gca, 'ydir', 'reverse'); axis equal; axis off;
  xlim([0.5 nc+0.5]); ylim([0.5 nl+0.5]);
end

function s = fmt(x, dec)
  x = x(isfinite(x));
  if isempty(x), s = '—'; return; end
  if numel(x) == 1, s = sprintf(['%.' num2str(dec) 'f'], x); return; end
  s = sprintf(['%.' num2str(dec) 'f ± %.' num2str(dec) 'f'], mean(x), std(x));
end

function q = prctile_s(v, p)
  v = sort(v(:)); q = v(max(1, min(numel(v), round(p/100*numel(v)))));
end
