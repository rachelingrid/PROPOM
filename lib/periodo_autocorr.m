function [per, ac_pico] = periodo_autocorr(x, janela, faixa)
% PERIODO_AUTOCORR  Periodo de um ciclo pela autocorrelacao (estimador no dominio do tempo).
%   Remove a tendencia lenta com media movel de 'janela' amostras (padrao 121 = 2 h a 1/min),
%   calcula a autocorrelacao do residuo e devolve o atraso do primeiro maximo local
%   dentro de 'faixa' (padrao [5 120] amostras) com autocorrelacao > 0,1.
%   per = NaN se nao houver ciclo detectavel.
  if nargin < 2, janela = 121; end
  if nargin < 3, faixa = [5 120]; end
  x = x(:);
  k = janela;
  base = conv(x, ones(k, 1) / k, 'same');
  h = x - base;
  h = h(k:end-k+1);
  h = h - mean(h);
  n = numel(h);
  L = min(faixa(2) + 1, n - 1);
  ac = zeros(L + 1, 1);
  for lag = 0:L
    ac(lag + 1) = sum(h(1:n-lag) .* h(1+lag:n));
  end
  ac = ac / ac(1);
  per = NaN;  ac_pico = NaN;
  for lag = max(faixa(1), 1):L-1
    if ac(lag + 1) > ac(lag) && ac(lag + 1) >= ac(lag + 2) && ac(lag + 1) > 0.1
      per = lag;  ac_pico = ac(lag + 1);
      return;
    end
  end
end
