function rodape_relatorio(txt, ax, linhas)
% Rodapé com notas metodológicas e aviso de documento de pesquisa.
  linhas{end+1} = sprintf('Documento de pesquisa (ProPOM / PEB-COPPE-UFRJ). Não constitui laudo diagnóstico. Emitido em %s.', ...
                          datestr(now, 'dd/mm/yyyy HH:MM'));
  y0 = 0.025 + 0.015 * (numel(linhas) - 1);
  plot(ax, [0.06 0.94], [y0 + 0.017 y0 + 0.017], '-', 'color', [.6 .6 .6], 'linewidth', 0.5);
  for k = 1:numel(linhas)
    txt(0.06, y0 - (k-1)*0.015, linhas{k}, 'fontsize', 7.5, 'color', [.25 .25 .25]);
  end
end
