function [nomes, datas] = listar_arquivos(pasta, padroes)
% Nomes dos arquivos da pasta que casam com os padrões (ex.: {'*.csv','*.CSV'}),
% sem duplicatas (no Windows *.csv e *.CSV devolvem os mesmos arquivos),
% em ordem alfabética. datas = datenum de modificação de cada um.
  nomes = {}; datas = [];
  for p = padroes
    l = dir(fullfile(pasta, p{1}));
    if isempty(l), continue; end
    l = l(~[l.isdir]);
    nomes = [nomes, {l.name}]; datas = [datas, [l.datenum]]; %#ok<AGROW>
  end
  [nomes, i] = unique(nomes); datas = datas(i);
end
