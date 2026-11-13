function L = localizar_pontos(T, visor, visor_util, P, manual)
% Etapa 3a: pontos anatômicos, nomeados pela anatomia do PARTICIPANTE.
%  N  = ápice do entalhe do dorso nasal (borda inferior do visor, região central)
%  OD = endocanto do olho direito
%  OE = endocanto do olho esquerdo
% Coordenadas em [linha coluna] nativas (1-based).
% 'manual' (struct opcional) substitui qualquer ponto informado (correção manual).

  L = struct('N', [NaN NaN], 'OD', [NaN NaN], 'OE', [NaN NaN], ...
             'origem_N', 'auto', 'origem_OD', 'auto', 'origem_OE', 'auto', 'ok', true, 'motivo', '');

  [~, col] = find(visor);
  c0 = min(col); c1 = max(col); larg = c1 - c0;
  cc = round(c0 + 0.3*larg) : round(c0 + 0.7*larg);
  base = NaN(size(cc));
  for k = 1:numel(cc)
    r = find(visor(:, cc(k)), 1, 'last');
    if ~isempty(r), base(k) = r; end
  end
  bmin = min(base);
  cols_apice = cc(base == bmin);
  L.N = [bmin + 1, round(mean(cols_apice))];   % primeira linha FORA da pele = ápice do entalhe
  if nargin >= 5 && isfield(manual, 'N') && all(isfinite(manual.N))
    L.N = manual.N; L.origem_N = 'manual';
  end

  % Suavização apenas para localizar o endocanto (média normalizada dentro da máscara)
  k = ones(P.janela_suav_px);
  num = conv2(T .* visor_util, k, 'same');
  den = conv2(double(visor_util), k, 'same');
  S = num ./ max(den, eps); S(~visor_util) = -Inf;

  px = @(mm) round(mm / P.mm_por_px);
  r0 = L.N(1) - px(P.endocanto_acima_mm);
  r1 = L.N(1) + px(P.endocanto_abaixo_mm);
  dmin = px(P.endocanto_dist_min_mm); dmax = px(P.endocanto_dist_max_mm);

  for olho = {'OD', 'OE'}
    nome = olho{1}; sg = sinal_lado(nome, P);
    cs = sort(L.N(2) + sg*(dmin:dmax));
    rs = max(1, r0):min(size(T,1), r1);
    cs = cs(cs >= 1 & cs <= size(T,2));
    sub = S(rs, cs);
    [mx, ix] = max(sub(:));
    if ~isfinite(mx)
      L.ok = false; L.motivo = ['endocanto não encontrado: ' nome];
      continue;
    end
    [a, b] = ind2sub(size(sub), ix);
    L.(nome) = [rs(a) cs(b)];
    if nargin >= 5 && isfield(manual, nome) && all(isfinite(manual.(nome)))
      L.(nome) = manual.(nome); L.(['origem_' nome]) = 'manual';
    end
  end
end
