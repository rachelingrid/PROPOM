function S = wilcoxon_pareado(x, y)
% WILCOXON_PAREADO  Teste de postos sinalizados de Wilcoxon para dados pareados.
%   S = wilcoxon_pareado(x, y) testa d = x - y (bicaudal), sem pacotes externos.
%
%   Mesma convencao do wilcox.test do R (paired = TRUE, exact = FALSE,
%   correct = TRUE): diferencas nulas sao descartadas, empates recebem posto
%   medio, a variancia tem correcao para empates e z usa correcao de continuidade.
%
%   Campos de saida:
%     n        pares com diferenca nao nula
%     V        soma dos postos das diferencas positivas (estatistica V do R)
%     z, p     estatistica normal e p bicaudal
%     r        tamanho de efeito r = z / sqrt(n)
%     r_rb     correlacao rank-bisserial pareada = (T+ - T-) / (T+ + T-)
%     rho1     autocorrelacao de lag 1 das diferencas
%     n_ef     n efetivo (aproximacao AR(1)): n (1 - rho1) / (1 + rho1)
%     z_aj, p_aj  z e p com a variancia inflada pela autocorrelacao
%
%   Observacao: o r antigo (script R) era obtido de qnorm(p/2); quando p
%   chega a zero numerico (n grande), z vira infinito e r = +/-Inf. Aqui z
%   e calculado diretamente de V, o que elimina esse problema.

  d = x(:) - y(:);
  d = d(~isnan(d));
  rho1 = autocorr_lag1(d);
  d = d(d ~= 0);
  n = numel(d);
  S = struct('n', n, 'V', NaN, 'z', NaN, 'p', NaN, 'r', NaN, 'r_rb', NaN, ...
             'rho1', rho1, 'n_ef', NaN, 'z_aj', NaN, 'p_aj', NaN);
  if n < 2
    return;
  end

  [rk, t] = postos_medios(abs(d));
  Tpos = sum(rk(d > 0));
  Tneg = sum(rk(d < 0));
  mu   = n * (n + 1) / 4;
  vr   = n * (n + 1) * (2 * n + 1) / 24 - sum(t.^3 - t) / 48;
  dif  = Tpos - mu;
  z    = (dif - 0.5 * sign(dif)) / sqrt(vr);

  S.V    = Tpos;
  S.z    = z;
  S.p    = erfc(abs(z) / sqrt(2));
  S.r    = z / sqrt(n);
  S.r_rb = (Tpos - Tneg) / (Tpos + Tneg);
  S.n_ef = n_efetivo(n, rho1);
  S.z_aj = z * sqrt(S.n_ef / n);
  S.p_aj = erfc(abs(S.z_aj) / sqrt(2));
end
