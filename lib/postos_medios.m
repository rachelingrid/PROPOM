function [rk, t] = postos_medios(v)
% POSTOS_MEDIOS  Postos com empates resolvidos pela media (equivale a tiedrank).
%   [rk, t] = postos_medios(v) devolve os postos de v e, em t, o tamanho de
%   cada grupo de empate (usado na correcao de variancia).

  v = v(:);
  n = numel(v);
  [vs, ord] = sort(v);
  rk = zeros(n, 1);
  t = [];
  i = 1;
  while i <= n
    j = i;
    while j < n && vs(j + 1) == vs(i)
      j = j + 1;
    end
    rk(ord(i:j)) = (i + j) / 2;
    if j > i
      t(end + 1, 1) = j - i + 1; %#ok<AGROW>
    end
    i = j + 1;
  end
  if isempty(t)
    t = 0;
  end
end
