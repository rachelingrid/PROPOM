function fig_salvar(h, arquivo)
% FIG_SALVAR  Exporta a figura em PNG (150 dpi) e fecha.
  print(h, arquivo, '-dpng', '-r150');
  close(h);
end
