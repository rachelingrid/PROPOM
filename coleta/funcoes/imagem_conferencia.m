function imagem_conferencia(arquivo_png, T, visor, visor_util, L, R, J, P)
% Etapa 10: imagem de conferência (PNG), sem janela gráfica (roda no octave-cli).
% Fundo: temperatura em tons de cinza (só para visualização).
% Contornos: amarelo = borda útil do visor | ciano = órbita |
%            verde = pele elegível (quadrante superior medial) |
%            vermelho = janela 3x3 do OD | rosa = janela 3x3 do OE |
%            magenta = ápice nasal | azul = endocantos
% Participante de frente: o OD aparece à ESQUERDA da imagem.
% Linhas finas laranja = eixos dos quadrantes.

  s = P.escala_png; m = P.margem_png;
  [lin, col] = find(visor);
  r0 = max(1, min(lin) - m); r1 = min(size(T,1), max(lin) + m);
  c0 = max(1, min(col) - m); c1 = min(size(T,2), max(col) + m);
  sub = T(r0:r1, c0:c1);

  v = T(visor);
  lo = prctile_simples(v, 2); hi = prctile_simples(v, 99.8);
  g = (sub - lo) / (hi - lo); g = min(max(g, 0), 1);
  g = kron(g, ones(s));
  img = cat(3, g, g, g);

  recorte = @(M) kron(double(M(r0:r1, c0:c1)), ones(s)) > 0;

  img = contorno(img, recorte(visor_util), [1 0.85 0]);
  for id = {'OD', 'OE'}
    O = R.(id{1});
    eixo = recorte((abs(O.u) < 0.71 | abs(O.v) < 0.71) & O.orbita);
    img = pinta(img, eixo & ~recorte(O.elegivel) & ~(conv2(double(eixo),ones(3),"same")==9), [1 0.55 0]);
    img = contorno(img, recorte(O.orbita), [0 0.9 1]);
    img = contorno(img, recorte(O.elegivel), [0 1 0]);
  end
  cores = struct('OD', [1 0 0], 'OE', [1 0.4 0.7]);
  for id = {'OD', 'OE'}
    Jo = J.(id{1});
    if Jo.ok
      w = false(size(T)); w(Jo.linha_centro-1:Jo.linha_centro+1, Jo.coluna_centro-1:Jo.coluna_centro+1) = true;
      img = contorno(img, recorte(w), cores.(id{1}));
    end
  end
  img = marca(img, L.N,  r0, c0, s, [1 0 1]);
  img = marca(img, L.OD, r0, c0, s, [0.2 0.4 1]);
  img = marca(img, L.OE, r0, c0, s, [0.2 0.4 1]);

  imwrite(img, arquivo_png);
end

function img = contorno(img, M, cor)
  e = conv2(double(M), ones(3), 'same') < 9 & M;   % pixels de borda (interna)
  img = pinta(img, e, cor);
end

function img = pinta(img, M, cor)
  for c = 1:3
    canal = img(:,:,c); canal(M) = cor(c); img(:,:,c) = canal;
  end
end

function img = marca(img, p, r0, c0, s, cor)
  if any(~isfinite(p)), return; end
  y = round((p(1) - r0 + 0.5) * s); x = round((p(2) - c0 + 0.5) * s);
  M = false(size(img,1), size(img,2));
  t = max(2, round(s/2));
  M(max(1,y-t):min(end,y+t), max(1,x-1):min(end,x+1)) = true;
  M(max(1,y-1):min(end,y+1), max(1,x-t):min(end,x+t)) = true;
  img = pinta(img, M, cor);
end

function q = prctile_simples(v, p)
  v = sort(v(:)); q = v(max(1, min(numel(v), round(p/100 * numel(v)))));
end
