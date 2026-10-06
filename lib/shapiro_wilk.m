function [W, p] = shapiro_wilk(x)
% SHAPIRO_WILK  Teste de normalidade de Shapiro-Wilk (algoritmo de Royston, 1995).
%   [W, p] = shapiro_wilk(x), valido para 12 <= n <= 5000.
%   Implementacao propria, sem o pacote statistics (norminv substituido por erfcinv).

  x = sort(x(~isnan(x(:))));
  n = numel(x);
  if n < 12 || n > 5000
    error('shapiro_wilk: n = %d fora do intervalo valido (12 a 5000).', n);
  end

  q  = ((1:n)' - 0.375) / (n + 0.25);
  m  = -sqrt(2) * erfcinv(2 * q);              % quantis normais esperados
  mm = m' * m;
  u  = 1 / sqrt(n);
  c  = m / sqrt(mm);

  an  = c(n)     + 0.221157*u - 0.147981*u^2 - 2.071190*u^3 + 4.434685*u^4 - 2.706056*u^5;
  an1 = c(n - 1) + 0.042981*u - 0.293762*u^2 - 1.752461*u^3 + 5.682633*u^4 - 3.582633*u^5;
  phi = (mm - 2*m(n)^2 - 2*m(n-1)^2) / (1 - 2*an^2 - 2*an1^2);

  a = m / sqrt(phi);
  a(n) = an;  a(n - 1) = an1;  a(1) = -an;  a(2) = -an1;

  W = (a' * x)^2 / sum((x - mean(x)).^2);

  ln = log(n);
  mu = 0.0038915*ln^3 - 0.083751*ln^2 - 0.31082*ln - 1.5861;
  sg = exp(0.0030302*ln^2 - 0.082676*ln - 0.4803);
  z  = (log(1 - W) - mu) / sg;
  p  = 0.5 * erfc(z / sqrt(2));
end
