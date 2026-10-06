function [xo, yo] = quebrar_lacunas(x, y, lim_min)
% QUEBRAR_LACUNAS  Insere NaN onde a serie tem lacuna, para o grafico nao ligar os pontos.
%   x em datenum (dias); lim_min = maior intervalo tolerado, em minutos (padrao 2).
  if nargin < 3, lim_min = 2; end
  x = x(:);  y = y(:);
  g = find(diff(x) * 1440 > lim_min);
  xo = x;  yo = y;
  for k = numel(g):-1:1
    xo = [xo(1:g(k)); NaN; xo(g(k)+1:end)];
    yo = [yo(1:g(k)); NaN; yo(g(k)+1:end)];
  end
end
