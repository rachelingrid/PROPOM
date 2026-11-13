function [cab, linhas] = ler_csv_texto(arquivo)
% Lê CSV (separador vírgula) como texto: cabeçalho + células.
% Aceita campos entre aspas (padrão do Excel): "Sem maquiagem, cremes" é um
% único campo; "" dentro de aspas vira ". Linhas iniciadas por # são comentários.
  txt = strrep(fileread(arquivo), sprintf('\r'), '');
  txt = regexprep(txt, '^\xEF\xBB\xBF', '');
  ls = strsplit(strtrim(txt), sprintf('\n'));
  ls = ls(~cellfun(@(x) isempty(strtrim(x)) || x(1) == '#', ls));
  cab = strtrim(dividir(ls{1}));
  linhas = cell(numel(ls) - 1, numel(cab));
  for i = 2:numel(ls)
    c = strtrim(dividir(ls{i}));
    c(end+1:numel(cab)) = {''};
    linhas(i-1, :) = c(1:numel(cab));
  end
end

function c = dividir(s)
  if ~any(s == '"')
    c = strsplit(s, ',', 'CollapseDelimiters', false); return;
  end
  c = {}; campo = ''; dentro = false; k = 1;
  while k <= numel(s)
    ch = s(k);
    if dentro
      if ch == '"'
        if k < numel(s) && s(k+1) == '"', campo(end+1) = '"'; k = k + 1;
        else, dentro = false; end
      else
        campo(end+1) = ch;
      end
    elseif ch == '"'
      dentro = true;
    elseif ch == ','
      c{end+1} = campo; campo = '';
    else
      campo(end+1) = ch;
    end
    k = k + 1;
  end
  c{end+1} = campo;
end
