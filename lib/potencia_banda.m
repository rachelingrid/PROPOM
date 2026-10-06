function [pot, per_pico] = potencia_banda(P, f, periodos)
% POTENCIA_BANDA  Potencia (variancia) contida numa banda de periodos e periodo dominante.
%   periodos = [Pmin Pmax] na mesma unidade de 1/f (ex.: minutos).
%   pot      = integral da PSD na banda (unidade^2) -> sqrt(pot) e o RMS da oscilacao
%   per_pico = periodo do maior pico da PSD dentro da banda
  fb = (f >= 1 / periodos(2)) & (f <= 1 / periodos(1));
  df = f(2) - f(1);
  pot = sum(P(fb)) * df;
  idx = find(fb);
  [~, k] = max(P(idx));
  per_pico = 1 / f(idx(k));
end
