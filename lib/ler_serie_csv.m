function [tn, temp, ur] = ler_serie_csv(arquivo)
% LER_SERIE_CSV  Le CSV de logger com cabecalho DATA_HORA,TEMP,UR.
%   DATA_HORA no formato AAAA-MM-DD hh:mm:ss.
%   tn em datenum (dias); temp em graus C; ur em %.
  fid = fopen(arquivo, 'r');
  if fid < 0
    error('Nao foi possivel abrir %s', arquivo);
  end
  fgetl(fid);                                  % cabecalho
  C = textscan(fid, '%s %f %f', 'Delimiter', ',');
  fclose(fid);
  c = char(C{1});                              % 'AAAA-MM-DD hh:mm:ss'
  dig = @(cols) (c(:, cols) - '0') * 10.^(numel(cols)-1:-1:0)';
  tn   = datenum(dig(1:4), dig(6:7), dig(9:10), dig(12:13), dig(15:16), dig(18:19));
  temp = C{2};
  ur   = C{3};
end
