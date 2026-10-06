function s = descrever_integridade(nome, tn)
% DESCREVER_INTEGRIDADE  Verifica ordem e espacamento de 1 min de uma serie e descreve as lacunas.
  dm = round(diff(tn) * 1440);
  if any(dm <= 0)
    error('%s: carimbos de tempo fora de ordem ou repetidos (%d ocorrencias).', nome, sum(dm <= 0));
  end
  g = find(dm > 1);
  s = sprintf('%s: %d amostras, de %s a %s', nome, numel(tn), datestr(tn(1), 'dd/mm/yyyy HH:MM'), ...
              datestr(tn(end), 'dd/mm/yyyy HH:MM'));
  if isempty(g)
    s = [s ', sem lacunas.'];
  else
    partes = arrayfun(@(k) sprintf('%s a %s', datestr(tn(k), 'dd/mm HH:MM'), datestr(tn(k + 1), 'dd/mm HH:MM')), ...
                      g, 'uniformoutput', false);
    s = [s sprintf(', com %d lacuna(s): %s (fora das janelas analisadas, que são verificadas minuto a minuto).', ...
                   numel(g), strjoin(partes', '; '))];
  end
end
