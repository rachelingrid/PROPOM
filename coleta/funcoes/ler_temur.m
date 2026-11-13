function M = ler_temur(pasta)
% Lê e junta TODOS os CSVs do termo-higrômetro na pasta TEMUR.
% Aceita exportações do Govee e similares:
%  - separador vírgula ou ponto e vírgula (com decimal em vírgula)
%  - data/hora na 1ª coluna: aaaa-mm-dd HH:MM[:SS] ou dd/mm/aaaa HH:MM[:SS]
%  - colunas identificadas pelo nome: temperatura (temp) e umidade (humid/umid/RH)
%  - temperatura em Fahrenheit é convertida para °C
% Retorna M.t (datenum), M.UR (%), M.T (°C), ordenados, sem horários repetidos.

  M = struct('t', zeros(0,1), 'UR', zeros(0,1), 'T', zeros(0,1), 'arquivos', {{}}, 'avisos', {{}});
  if ~isfolder(pasta), return; end
  nomes = listar_arquivos(pasta, {'*.csv', '*.CSV'});
  t = []; ur = []; tc = [];
  for f = nomes
    arq = fullfile(pasta, f{1});
    try
      [a, b, c] = ler_um(arq);
      t = [t; a]; ur = [ur; b]; tc = [tc; c]; %#ok<AGROW>
      M.arquivos{end+1} = f{1};
    catch err
      M.avisos{end+1} = sprintf('%s: %s', f{1}, err.message);
    end
  end
  ok = isfinite(t) & isfinite(ur) & isfinite(tc);
  t = t(ok); ur = ur(ok); tc = tc(ok);
  [t, i] = unique(t);                     % mantém uma leitura por horário
  M.t = t; M.UR = ur(i); M.T = tc(i);
end

function [t, ur, tc] = ler_um(arq)
  txt = strrep(fileread(arq), sprintf('\r'), '');
  txt = regexprep(txt, '^\xEF\xBB\xBF', '');            % BOM
  ls = strsplit(strtrim(txt), sprintf('\n'));
  sep = ',';
  if numel(strfind(ls{1}, ';')) > numel(strfind(ls{1}, ',')), sep = ';'; end
  cab = lower(remover_acentos(strtrim(strsplit(ls{1}, sep, 'CollapseDelimiters', false))));
  it = find(~cellfun(@isempty, regexp(cab, 'temp')), 1);
  iu = find(~cellfun(@isempty, regexp(cab, 'humid|umid')), 1);
  if isempty(iu)   % abreviações: UR, RH (sem confundir com 'temperatURa')
    iu = find(~cellfun(@isempty, regexp(cab, '^(ur|rh)\>|[ _(](ur|rh)\>')), 1);
  end
  if isempty(it) || isempty(iu), error('colunas de temperatura/umidade não identificadas'); end
  fahr = ~isempty(regexp(cab{it}, 'fahrenheit|\(f\)|_f$|°f', 'once'));
  n = numel(ls) - 1;
  t = NaN(n,1); ur = NaN(n,1); tc = NaN(n,1);
  for i = 1:n
    c = strtrim(strsplit(ls{i+1}, sep, 'CollapseDelimiters', false));
    if numel(c) < max(it, iu), continue; end
    t(i)  = parse_datahora(c{1});
    tc(i) = num(c{it}, sep);
    ur(i) = num(c{iu}, sep);
  end
  if fahr, tc = (tc - 32) * 5/9; end
end

function x = num(s, sep)
  s = regexprep(s, '["%\s]', '');
  if strcmp(sep, ';'), s = strrep(s, ',', '.'); end
  x = str2double(s);
end
