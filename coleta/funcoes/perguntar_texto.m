function s = perguntar_texto(msg, validar, erro)
% Pergunta texto; 'validar' (opcional) é uma função que retorna true/false.
  while true
    s = strtrim(input([msg ': '], 's'));
    if nargin < 2 || isempty(validar) || validar(s), return; end
    if nargin >= 3, printf('  %s\n', erro); else, printf('  Valor inválido.\n'); end
  end
end
