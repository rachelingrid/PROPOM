function v = iqr_amostral(x)
% IQR_AMOSTRAL  Intervalo interquartil (quantis por interpolacao linear, tipo 7 do R).
  x = sort(x(~isnan(x(:))));
  n = numel(x);
  q = @(f) interp1((0:n-1)' / (n - 1), x, f);
  v = q(0.75) - q(0.25);
end
