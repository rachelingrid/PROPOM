function C = cores_propom()
% CORES_PROPOM  Paleta fixa dos graficos (RGB 0-1). A cor segue a entidade:
%   LAB (ambiente) e sempre laranja; PRO (cabine) e sempre azul.
  hex = @(h) sscanf(h(2:end), '%2x%2x%2x')' / 255;
  C.pro   = hex('#2a78d6');   % cabine / prototipo
  C.lab   = hex('#eb6834');   % laboratorio / ambiente
  C.c3    = hex('#1baf7a');   % terceira serie
  C.tinta = hex('#0b0b0b');
  C.sec   = hex('#52514e');
  C.grade = hex('#e4e3df');
  C.faixa = hex('#efeeea');   % sombreamento de fases/janelas
  C.ajuste = hex('#52514e');
end
