function s = campo_csv(x)
% Converte um valor em campo CSV: números com ponto decimal, texto entre
% aspas quando tiver vírgula ou aspas (padrão do Excel), sem quebras de linha.
  if isnumeric(x) || islogical(x)
    if isempty(x) || any(isnan(x)), s = ''; else, s = num2str(x, '%.6g'); end
    return;
  end
  s = regexprep(char(x), '[\r\n]+', ' ');
  if any(s == ',') || any(s == '"')
    s = ['"' strrep(s, '"', '""') '"'];
  end
end
