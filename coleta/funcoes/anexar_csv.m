function anexar_csv(arquivo, cabecalho, valores)
% Acrescenta uma linha a uma tabela-mestre CSV (cria com cabeçalho se não existir).
% Texto com vírgula vai entre aspas (padrão do Excel).
  novo = ~exist(arquivo, 'file');
  fid = fopen(arquivo, 'a');
  if fid < 0, error('Não foi possível abrir %s (está aberto no Excel?)', arquivo); end
  if novo, fprintf(fid, '%s\n', strjoin(cellfun(@campo_csv, cabecalho, 'UniformOutput', false), ',')); end
  v = cellfun(@campo_csv, valores, 'UniformOutput', false);
  fprintf(fid, '%s\n', strjoin(v, ','));
  fclose(fid);
end
