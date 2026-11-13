function d = parse_datahora(s)
% Converte data/hora em datenum. Aceita:
%   aaaa-mm-dd HH:MM[:SS]   |   aaaa/mm/dd HH:MM[:SS]   |   dd/mm/aaaa HH:MM[:SS]
% (formato brasileiro dd/mm; aspas e o separador 'T' são aceitos). NaN se falhar.
  d = NaN;
  s = strtrim(regexprep(s, '"', ''));
  t = regexp(s, '^(\d{4})[-/](\d{1,2})[-/](\d{1,2})[ T]+(\d{1,2}):(\d{2})(?::(\d{2}))?', 'tokens', 'once');
  if ~isempty(t)
    a = t{1}; m = t{2}; di = t{3};
  else
    t = regexp(s, '^(\d{1,2})/(\d{1,2})/(\d{4})[ T]+(\d{1,2}):(\d{2})(?::(\d{2}))?', 'tokens', 'once');
    if isempty(t), return; end
    di = t{1}; m = t{2}; a = t{3};
  end
  seg = 0; if numel(t) >= 6 && ~isempty(t{6}), seg = str2double(t{6}); end
  d = datenum(str2double(a), str2double(m), str2double(di), str2double(t{4}), str2double(t{5}), seg);
end
