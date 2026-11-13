function salvar_registro(arquivo, R)
% Grava o registro da coleta (cell N x 3: chave, descrição, valor) como CSV.
% Regrava o arquivo inteiro a cada etapa (salvamento progressivo).
  fid = fopen(arquivo, 'w');
  if fid < 0, error('Não foi possível gravar %s', arquivo); end
  fprintf(fid, 'chave,descricao,valor\n');
  for i = 1:size(R, 1)
    fprintf(fid, '%s,%s,%s\n', campo_csv(R{i,1}), campo_csv(R{i,2}), campo_csv(R{i,3}));
  end
  fclose(fid);
end
