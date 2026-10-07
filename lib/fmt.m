function s = fmt(x, casas, sinal)
% FMT  Numero em formato pt-BR (virgula decimal, sinal de menos tipografico).
%   s = fmt(x, casas)        ex.: fmt(-1.234, 2) -> '−1,23'
%   s = fmt(x, casas, true)  forca '+' em positivos
  if nargin < 2, casas = 2; end
  if nargin < 3, sinal = false; end
  if isnan(x)
    s = '—';  return;
  elseif isinf(x)
    s = ifelse_str(x > 0, '∞', '−∞');  return;
  end
  s = sprintf(sprintf('%%.%df', casas), abs(x));
  s = strrep(s, '.', ',');
  if x < 0 && ~all(s == '0' | s == ',')
    s = ['−' s];
  elseif sinal && x > 0
    s = ['+' s];
  end
end

function s = ifelse_str(c, a, b)
  if c, s = a; else, s = b; end
end
