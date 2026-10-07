function S = ajuste_exponencial(t, y)
% AJUSTE_EXPONENCIAL  Ajusta y = Tinf + A * exp(-t / tau) (curva de acomodacao).
%   Para cada tau de uma grade, Tinf e A saem por minimos quadrados lineares;
%   escolhe-se o tau de menor erro e refina-se a grade em torno dele.
%   Campos: tinf, A, tau, r2, yhat.
  t = t(:) - t(1);  y = y(:);
  sst = sum((y - mean(y)).^2);
  grade = logspace(log10(0.2), log10(50 * max(t)), 400);
  for passada = 1:3
    sse = inf(size(grade));
    for k = 1:numel(grade)
      X = [ones(size(t)), exp(-t / grade(k))];
      c = X \ y;
      sse(k) = sum((y - X * c).^2);
    end
    [~, kb] = min(sse);
    lo = grade(max(kb - 1, 1));  hi = grade(min(kb + 1, numel(grade)));
    melhor = grade(kb);
    grade = linspace(lo, hi, 200);
  end
  X = [ones(size(t)), exp(-t / melhor)];
  c = X \ y;
  S.tinf = c(1);  S.A = c(2);  S.tau = melhor;
  S.yhat = X * c;
  S.r2 = 1 - sum((y - S.yhat).^2) / sst;
end
