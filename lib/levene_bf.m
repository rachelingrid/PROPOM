function S = levene_bf(x, y)
% LEVENE_BF  Teste de Levene centrado na mediana (Brown-Forsythe) para 2 grupos.
%   Equivale a car::leveneTest (center = median) do R, usado no script antigo.
%   Saida: F, gl1, gl2, p.
  x = x(~isnan(x(:)));
  y = y(~isnan(y(:)));
  zx = abs(x - median(x));
  zy = abs(y - median(y));
  z  = [zx; zy];
  nx = numel(zx);  ny = numel(zy);  N = nx + ny;  k = 2;
  zm = mean(z);
  ssb = nx * (mean(zx) - zm)^2 + ny * (mean(zy) - zm)^2;
  ssw = sum((zx - mean(zx)).^2) + sum((zy - mean(zy)).^2);
  F = (ssb / (k - 1)) / (ssw / (N - k));
  S.F = F;  S.gl1 = k - 1;  S.gl2 = N - k;
  S.p = f_sobrevivencia(F, k - 1, N - k);
end

function p = f_sobrevivencia(F, d1, d2)
% P(F > f) pela beta incompleta regularizada (funcao nativa do Octave).
  if F <= 0
    p = 1;
  else
    p = betainc(d2 / (d2 + d1 * F), d2 / 2, d1 / 2);
  end
end
