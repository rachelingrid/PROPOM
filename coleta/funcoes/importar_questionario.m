function Q = importar_questionario(P)
% Lista os CSVs em ANAMNESE\QUESTIONARIOS (baixados do Mentaltracking) e
% importa a resposta escolhida. Retorna campos e valores de UMA resposta.
  Q = struct('arquivo', '', 'cabecalho', {{}}, 'valores', {{}});
  while true
    [nomes, datas] = listar_arquivos(P.pasta.QUESTIONARIOS, {'*.csv', '*.CSV'});
    if isempty(nomes)
      printf('  Nenhum CSV em %s\n', P.pasta.QUESTIONARIOS);
      if perguntar_sn('  Copiou o arquivo agora e quer procurar de novo'), continue; end
      return;
    end
    [~, o] = sort(datas, 'descend'); nomes = nomes(o);     % mais recente primeiro
    for i = 1:numel(nomes), printf('   [%d] %s\n', i, nomes{i}); end
    s = perguntar_texto('  Número do arquivo (0 = cancelar)', ...
          @(s) any(str2double(s) == 0:numel(nomes)));
    k = str2double(s);
    if k == 0, return; end
    f = fullfile(P.pasta.QUESTIONARIOS, nomes{k});
    [cab, lin] = ler_csv_texto(f);
    if isempty(lin), printf('  Arquivo sem respostas.\n'); continue; end
    r = 1;
    if size(lin, 1) > 1
      for i = 1:size(lin, 1)
        printf('   [%d] %s\n', i, strjoin(lin(i, 1:min(3, end)), ' | '));
      end
      r = str2double(perguntar_texto('  Número da resposta deste participante', ...
            @(s) any(str2double(s) == 1:size(lin, 1))));
    end
    Q.arquivo = f; Q.cabecalho = cab; Q.valores = lin(r, :);
    printf('  Questionário importado (%d campos).\n', numel(cab));
    return;
  end
end
