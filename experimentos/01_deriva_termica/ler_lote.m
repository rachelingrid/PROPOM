function L = ler_lote(arq)
% LER_LOTE  Le o CSV de saida do AMT.m (uma linha por quadro termico).
%   Colunas: arquivo, data, UR, Tar, Tmax, Tmin, Tmed, Tmediana, DP, Var, Amplitude.
%   O numero do quadro vem do nome do arquivo (ex.: 2025072500520E.CSV -> 520).
  fid = fopen(arq, 'r');
  fgetl(fid);
  C = textscan(fid, '%s %s %f %f %f %f %f %f %f %f %f', 'Delimiter', ',');
  fclose(fid);
  nomes = char(C{1});
  L.quadro   = str2num(nomes(:, 9:13)); %#ok<ST2NM>
  L.tmax     = C{5};  L.tmin = C{6};  L.tmed = C{7};  L.tmediana = C{8};
  L.dp       = C{9};  L.amp  = C{11};
end
