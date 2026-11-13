function x = perguntar_numero(rotulo, unidade, faixa)
% Pergunta um número (aceita vírgula decimal). Enter em branco = não medido (NaN).
% Valor fora da faixa pede confirmação.
  if isempty(unidade), u = ''; else, u = [' (' unidade ')']; end
  while true
    s = strtrim(input(sprintf('  %s%s [Enter = não medido]: ', rotulo, u), 's'));
    if isempty(s), x = NaN; return; end
    x = str2double(strrep(s, ',', '.'));
    if isnan(x), printf('  Digite um número.\n'); continue; end
    if x >= faixa(1) && x <= faixa(2), return; end
    if perguntar_sn(sprintf('  %g está fora de %g–%g. Confirmar', x, faixa(1), faixa(2))), return; end
  end
end
