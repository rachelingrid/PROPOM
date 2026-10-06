function s = html_tabela(cab, linhas, nota)
% HTML_TABELA  Monta uma tabela HTML.
%   cab    : cell 1xC com os titulos das colunas
%   linhas : cell LxC com o conteudo (texto ja formatado; pode conter HTML)
%   nota   : (opcional) texto da nota de rodape da tabela
%   A primeira coluna e alinhada a esquerda; as demais (numericas) a direita.
  s = sprintf('<div class="tabela"><table>\n<thead><tr>');
  for j = 1:numel(cab)
    s = [s sprintf('<th>%s</th>', cab{j})]; %#ok<AGROW>
  end
  s = [s sprintf('</tr></thead>\n<tbody>\n')];
  for i = 1:size(linhas, 1)
    s = [s '<tr>']; %#ok<AGROW>
    for j = 1:size(linhas, 2)
      s = [s sprintf('<td>%s</td>', linhas{i, j})]; %#ok<AGROW>
    end
    s = [s sprintf('</tr>\n')]; %#ok<AGROW>
  end
  s = [s '</tbody></table>'];
  if nargin >= 3 && ~isempty(nota)
    s = [s sprintf('<p class="nota-tabela">%s</p>', nota)];
  end
  s = [s '</div>'];
end
