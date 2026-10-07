function rho = autocorr_lag1(x)
% AUTOCORR_LAG1  Autocorrelacao amostral de lag 1 (serie centrada na media).
  x = x(:);
  x = x(~isnan(x)) - mean(x(~isnan(x)));
  den = sum(x.^2);
  if numel(x) < 3 || den == 0
    rho = 0;
    return;
  end
  rho = sum(x(1:end-1) .* x(2:end)) / den;
end
