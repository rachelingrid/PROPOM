function [P, f] = psd_welch(x, fs, nseg)
% PSD_WELCH  Densidade espectral de potencia unilateral pelo metodo de Welch.
%   [P, f] = psd_welch(x, fs, nseg)
%     x     serie temporal (amostragem uniforme, sem lacunas)
%     fs    frequencia de amostragem (ex.: 1 amostra/min -> fs = 1, f em ciclos/min)
%     nseg  comprimento de cada segmento (janela de Hann, sobreposicao de 50%)
%   A tendencia linear de cada segmento e removida antes da FFT.
%   Normalizacao: sum(P) * df ~= variancia de x (teorema de Parseval).

  x = x(:);
  n = numel(x);
  nseg = min(nseg, n);
  passo = floor(nseg / 2);
  ini = 1:passo:(n - nseg + 1);
  w = 0.5 - 0.5 * cos(2 * pi * (0:nseg-1)' / nseg);   % Hann periodica
  U = sum(w.^2);
  tt = (1:nseg)';
  X = [ones(nseg, 1), tt];
  acc = zeros(floor(nseg / 2) + 1, 1);
  for k = ini
    s = x(k:k + nseg - 1);
    s = s - X * (X \ s);
    F = fft(w .* s);
    acc = acc + abs(F(1:floor(nseg / 2) + 1)).^2;
  end
  P = acc / numel(ini) / (fs * U);
  P(2:end-1) = 2 * P(2:end-1);
  f = (0:floor(nseg / 2))' * fs / nseg;
end
