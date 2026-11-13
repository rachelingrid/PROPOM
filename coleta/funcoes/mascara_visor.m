function [visor, visor_util, limiar] = mascara_visor(T, P)
% Máscara da pele vista pelo visor: limiar de Otsu (fundo ~22 °C x pele >30 °C),
% maior componente conectado, e erosão da borda (pixels mistos/contato).
% Usa só Octave puro (sem pacote image).

  v = T(isfinite(T));
  bordas = linspace(min(v), max(v), 257);
  h = histc(v, bordas(1:end-1)); h = h(:) / sum(h);
  centros = (bordas(1:end-1) + bordas(2:end)) / 2; centros = centros(:);
  w0 = cumsum(h); m0 = cumsum(h .* centros); mt = m0(end);
  sb = (mt * w0 - m0).^2 ./ (w0 .* (1 - w0) + eps);
  [~, k] = max(sb);
  limiar = centros(k);

  m = T > limiar;
  visor = maior_componente(m);

  r = max(1, round(P.margem_borda_mm / P.mm_por_px));
  k = ones(2*r + 1);
  visor_util = conv2(double(visor), k, 'same') == numel(k);   % erosão quadrada
end

function out = maior_componente(m)
  [nl, nc] = size(m);
  rot = zeros(nl, nc); n = 0; tam = [];
  viz = [-1 0; 1 0; 0 -1; 0 1];
  for idx = find(m)'
    if rot(idx), continue; end
    n = n + 1; fila = idx; rot(idx) = n; p = 1;
    while p <= numel(fila)
      [i, j] = ind2sub([nl nc], fila(p)); p = p + 1;
      for q = 1:4
        a = i + viz(q,1); b = j + viz(q,2);
        if a >= 1 && a <= nl && b >= 1 && b <= nc && m(a,b) && ~rot(a,b)
          rot(a,b) = n; fila(end+1) = sub2ind([nl nc], a, b); %#ok<AGROW>
        end
      end
    end
    tam(n) = numel(fila); %#ok<AGROW>
  end
  if n == 0, out = false(nl, nc); return; end
  [~, g] = max(tam);
  out = rot == g;
end
