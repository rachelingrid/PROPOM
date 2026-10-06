function eixo_estilo(ax, rot_x, rot_y, titulo)
% EIXO_ESTILO  Grade horizontal discreta, rotulos e titulo alinhado a esquerda.
  C = cores_propom();
  if nargin < 1 || isempty(ax), ax = gca; end
  set(ax, 'ygrid', 'on', 'xgrid', 'off', 'layer', 'bottom', 'box', 'off');
  if nargin >= 2 && ~isempty(rot_x), xlabel(ax, rot_x, 'color', C.sec); end
  if nargin >= 3 && ~isempty(rot_y), ylabel(ax, rot_y, 'color', C.sec); end
  if nargin >= 4 && ~isempty(titulo)
    title(ax, titulo, 'color', C.tinta, 'fontweight', 'bold', 'fontsize', 10, ...
          'horizontalalignment', 'left', 'units', 'normalized', 'position', [0 1.03]);
  end
end
