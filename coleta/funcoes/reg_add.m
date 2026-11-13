function R = reg_add(R, chave, descricao, valor)
% Acrescenta ou substitui uma entrada do registro.
  i = find(strcmp(R(:,1), chave), 1);
  if isempty(i), i = size(R, 1) + 1; end
  R(i, :) = {chave, descricao, valor};
end
