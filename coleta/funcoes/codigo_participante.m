function c = codigo_participante(nome, nascimento, sexo, quando)
% Código pseudonimizado: DDMMAAAA + inicial do 1º e 2º nomes + F/M + _AAAAMMDD-HHMM
% Ignora partículas (de, da, do, das, dos, e). Nome único -> 2ª inicial '*'.
  p = strsplit(upper(remover_acentos(strtrim(nome))));
  p = p(~cellfun(@isempty, p));
  p = p(~ismember(p, {'DE','DA','DO','DAS','DOS','E','D'''}));
  i1 = p{1}(1); i2 = '*';
  if numel(p) >= 2, i2 = p{2}(1); end
  d = strsplit(nascimento, '/');
  c = sprintf('%s%s%s%s%s%s_%s', d{1}, d{2}, d{3}, i1, i2, upper(sexo), datestr(quando, 'yyyymmdd-HHMM'));
end
