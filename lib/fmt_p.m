function s = fmt_p(p)
% FMT_P  Valor-p para exibicao: '< 0,001' abaixo de 0,001; tres casas acima.
  if isnan(p)
    s = '—';
  elseif p < 0.001
    s = '&lt; 0,001';
  else
    s = strrep(sprintf('%.3f', p), '.', ',');
  end
end
