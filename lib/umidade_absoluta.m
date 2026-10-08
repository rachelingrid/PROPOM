function ua = umidade_absoluta(T, UR)
% UMIDADE_ABSOLUTA  Umidade absoluta (g/m^3) a partir da temperatura (graus C) e da UR (%).
%   Pressao de saturacao pela formula de Magnus (coeficientes WMO: 6,112 hPa; 17,62; 243,12 C).
%   Separa a mudanca no conteudo de vapor da mudanca de UR causada apenas pela temperatura.
  es = 6.112 .* exp(17.62 .* T ./ (243.12 + T));       % hPa
  ua = 216.7 .* (UR ./ 100 .* es) ./ (273.15 + T);      % g/m^3
end
