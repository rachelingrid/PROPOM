function J = selecionar_janela_3x3(T, elegivel)
% Etapas 7-9: percorre TODAS as janelas 3x3 inteiramente contidas na máscara
% elegível, escolhe a de maior temperatura média e calcula, nos MESMOS nove
% pixels da matriz original: máximo, mínimo, média, mediana, desvio padrão,
% variância e amplitude.
% Desvio padrão e variância amostrais (denominador n-1 = 8).

  J = struct('ok', false, 'n_janelas', 0, 'n_empates', 0, ...
             'linha_centro', NaN, 'coluna_centro', NaN, 'valores', NaN(3), ...
             'maximo', NaN, 'minimo', NaN, 'media', NaN, 'mediana', NaN, ...
             'desvio_padrao', NaN, 'variancia', NaN, 'amplitude', NaN);

  k = ones(3);
  cont = conv2(double(elegivel), k, 'same');
  Tz = T; Tz(~elegivel) = 0;
  soma = conv2(Tz, k, 'same');
  valida = cont == 9;
  valida([1 end], :) = false; valida(:, [1 end]) = false;   % janela inteira dentro da matriz
  J.n_janelas = sum(valida(:));
  if J.n_janelas == 0, return; end

  media = soma / 9; media(~valida) = -Inf;
  mx = max(media(:));
  idx = find(media == mx);
  J.n_empates = numel(idx) - 1;
  [i, j] = ind2sub(size(T), idx(1));       % empate: primeira em ordem coluna-maior (registrado)

  W = T(i-1:i+1, j-1:j+1);                  % valores ORIGINAIS
  w = W(:);
  J.ok = true;
  J.linha_centro = i; J.coluna_centro = j; J.valores = W;
  J.maximo = max(w); J.minimo = min(w);
  J.media = mean(w); J.mediana = median(w);
  J.desvio_padrao = std(w); J.variancia = var(w);
  J.amplitude = J.maximo - J.minimo;
end
