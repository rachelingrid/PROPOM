function [f, ax, txt, y] = relatorio_base(titulo, info)
% Página A4 com cabeçalho padrão do ProPOM. Retorna a figura, o eixo de
% texto (coordenadas normalizadas 0-1), a função txt(x, y, texto, ...) e a
% altura y logo abaixo do cabeçalho.
  f = figure('visible', 'off', 'paperunits', 'centimeters', 'papersize', [21 29.7], ...
             'paperposition', [0 0 21 29.7], 'color', 'w');
  ax = axes('position', [0 0 1 1], 'visible', 'off'); xlim(ax, [0 1]); ylim(ax, [0 1]); hold(ax, 'on');
  txt = @(x, y, s, varargin) text(ax, x, y, s, 'units', 'normalized', 'interpreter', 'none', varargin{:});

  txt(0.06, 0.968, 'ProPOM — Proxy Periorbital Medial', 'fontsize', 9, 'color', [.35 .35 .35]);
  txt(0.06, 0.948, titulo, 'fontsize', 15, 'fontweight', 'bold');
  txt(0.06, 0.922, sprintf('Nome: %s', info.nome), 'fontsize', 11);
  txt(0.06, 0.903, sprintf('Data de nascimento: %s   (%s anos)   Sexo: %s', info.nascimento, info.idade, info.sexo), 'fontsize', 10);
  txt(0.62, 0.922, sprintf('Coleta: %s', info.data_coleta), 'fontsize', 10);
  txt(0.62, 0.903, sprintf('Código: %s', info.codigo), 'fontsize', 8.5, 'color', [.3 .3 .3]);
  plot(ax, [0.06 0.94], [0.89 0.89], 'k-', 'linewidth', 0.8);
  y = 0.865;
end
