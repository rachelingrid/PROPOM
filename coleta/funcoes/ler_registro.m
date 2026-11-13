function [R, get] = ler_registro(arquivo)
% Lê o registro da coleta. get('chave') devolve o valor (texto, '' se ausente).
  [~, lin] = ler_csv_texto(arquivo);
  R = lin;
  get = @(k) valor(R, k);
end
function v = valor(R, k)
  i = find(strcmp(R(:,1), k), 1);
  if isempty(i), v = ''; else, v = R{i,3}; end
end
