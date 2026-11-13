function y = secao_relatorio(txt, ax, y, titulo)
% Título de seção com filete; devolve o y para a primeira linha da seção.
  txt(0.06, y, titulo, 'fontsize', 12, 'fontweight', 'bold');
  plot(ax, [0.06 0.94], [y - 0.011 y - 0.011], '-', 'color', [.75 .75 .75], 'linewidth', 0.5);
  y = y - 0.03;
end
