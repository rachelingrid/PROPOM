function escrever_csv(arq, cab, rotulos, M)
% ESCREVER_CSV  Grava uma tabela de resultados: 1a coluna texto, demais numericas.
  fid = fopen(arq, 'w');
  fprintf(fid, '%s\n', strjoin(cab, ','));
  for i = 1:size(M, 1)
    fprintf(fid, '%s', rotulos{i});
    fprintf(fid, ',%.6g', M(i, :));
    fprintf(fid, '\n');
  end
  fclose(fid);
end
