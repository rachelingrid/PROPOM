function A = ler_ambiente(P, momento)
% Checagem de UR (%) e temperatura do protótipo (°C) durante a coleta.
% Se a pasta TEMUR tiver leitura recente (até P.temur_idade_max_min), oferece
% usá-la; senão, a operadora digita o valor lido no visor do termo-higrômetro.
% (Os valores no MOMENTO DE CADA IMAGEM são calculados no processamento.)
  A = struct('momento', momento, 'UR', NaN, 'T', NaN, 'origem', 'digitado', 'hora_leitura', '');
  M = ler_temur(P.pasta.TEMUR);
  if ~isempty(M.t)
    idade = (now - M.t(end)) * 1440;
    if idade >= 0 && idade <= P.temur_idade_max_min
      printf('  Última leitura em TEMUR: %s | UR = %.1f %% | T = %.2f °C\n', ...
             datestr(M.t(end), 'HH:MM:SS'), M.UR(end), M.T(end));
      if perguntar_sn('  Usar essa leitura')
        A.UR = M.UR(end); A.T = M.T(end); A.origem = 'TEMUR';
        A.hora_leitura = datestr(M.t(end), 'yyyy-mm-dd HH:MM:SS');
        return;
      end
    end
  end
  A.UR = perguntar_numero('Umidade relativa do ar no visor do termo-higrômetro', '%', [0 100]);
  A.T  = perguntar_numero('Temperatura do protótipo no visor do termo-higrômetro', '°C', [0 50]);
  A.hora_leitura = datestr(now, 'yyyy-mm-dd HH:MM:SS');
end
