function S = tendencia_linear(t, y)
% TENDENCIA_LINEAR  Inclinacao por minimos quadrados com IC 95% corrigido
%   para autocorrelacao dos residuos, e inclinacao robusta de Sen (Theil-Sen).
%
%   Campos: b (inclinacao), a (intercepto), ic (IC 95% de b), r2,
%           rho1 (autocorr. lag 1 dos residuos), n, n_ef, sen, res_dp.

  t = t(:);  y = y(:);
  ok = ~isnan(t) & ~isnan(y);
  t = t(ok);  y = y(ok);
  n = numel(y);
  X = [ones(n, 1), t];
  coef = X \ y;
  res  = y - X * coef;
  rho1 = autocorr_lag1(res);
  ne   = n_efetivo(n, rho1);

  s2  = sum(res.^2) / (n - 2);
  sxx = sum((t - mean(t)).^2);
  se  = sqrt(s2 / sxx);
  gl  = max(ne - 2, 1);
  se_aj = se * sqrt((n - 2) / gl);           % variancia inflada pela autocorrelacao
  tc  = t_quantil(0.975, gl);

  S.a = coef(1);  S.b = coef(2);
  S.ic = coef(2) + [-1, 1] * tc * se_aj;
  S.r2 = 1 - sum(res.^2) / sum((y - mean(y)).^2);
  S.rho1 = rho1;  S.n = n;  S.n_ef = ne;
  S.res_dp = sqrt(s2);
  S.sen = inclinacao_sen(t, y);
end

function b = inclinacao_sen(t, y)
  n = numel(y);
  [I, J] = find(triu(true(n), 1));
  dt = t(J) - t(I);
  ok = dt ~= 0;
  b = median((y(J(ok)) - y(I(ok))) ./ dt(ok));
end
