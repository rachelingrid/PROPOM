function R = regioes_orbitais(L, visor_util, T, P)
% Etapas 3b, 5 e 6: região orbital anatômica de cada olho (OD, OE), quatro
% quadrantes orientados pela cabeça e pele elegível do quadrante superior medial.
%
% A órbita é uma elipse ancorada no endocanto e orientada pelo eixo
% intercantal. Ela NÃO depende da abertura palpebral: com olhos fechados a
% região é a mesma.
%
% Quadrantes (código no mapa): 1 = superior medial, 2 = superior lateral,
%                               3 = inferior medial, 4 = inferior lateral.
% Medial = em direção ao dorso nasal; superior = em direção à sobrancelha.

  [nl, nc] = size(visor_util);
  [C, Lc] = meshgrid(1:nc, 1:nl);          % C = coluna (x), Lc = linha (y, para baixo)

  % eixo intercantal orientado da esquerda para a direita da IMAGEM
  if sinal_lado('OD', P) < 0, pE = L.OD; pD = L.OE; else, pE = L.OE; pD = L.OD; end
  e = [pD(2) - pE(2), pD(1) - pE(1)];        % (dx, dy)
  R.theta_graus = atan2d(e(2), e(1));        % inclinação da cabeça no plano da imagem
  e = e / norm(e);
  n_cima = [e(2), -e(1)];                    % normal apontando para cima

  a = P.orbita_largura_mm / 2 / P.mm_por_px;
  b = P.orbita_altura_mm  / 2 / P.mm_por_px;
  desloc = a - P.orbita_medial_mm / P.mm_por_px;   % centro lateral ao endocanto

  for olho = {'OD', 'OE'}
    id = olho{1}; canto = L.(id);
    med = -sinal_lado(id, P) * e;                  % vetor medial (rumo ao nariz)
    cx = canto(2) - desloc * med(1);
    cy = canto(1) - desloc * med(2);
    dx = C - cx; dy = Lc - cy;
    u = dx * med(1) + dy * med(2);                 % >0 = medial
    v = dx * n_cima(1) + dy * n_cima(2);           % >0 = superior
    orb = (u/a).^2 + (v/b).^2 <= 1;

    quad = zeros(nl, nc);
    quad(orb & u >  0 & v >  0) = 1;
    quad(orb & u <= 0 & v >  0) = 2;
    quad(orb & u >  0 & v <= 0) = 3;
    quad(orb & u <= 0 & v <= 0) = 4;

    R.(id).u = u; R.(id).v = v;
    R.(id).centro     = [cy cx];
    R.(id).orbita     = orb;
    R.(id).quadrantes = quad;
    R.(id).elegivel   = quad == 1 & visor_util & isfinite(T);
    R.(id).frac_orbita_no_visor = sum(orb(:) & visor_util(:)) / max(1, sum(orb(:)));
  end
  R.a_px = a; R.b_px = b;
end
