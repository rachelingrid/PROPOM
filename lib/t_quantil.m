function q = t_quantil(p, gl)
% T_QUANTIL  Quantil da distribuicao t de Student (substitui tinv do pacote statistics).
%   Resolve P(T <= q) = p por bissecao, usando a beta incompleta nativa.
  if gl > 1e4
    q = -sqrt(2) * erfcinv(2 * p);
    return;
  end
  lo = -1e3;  hi = 1e3;
  for k = 1:200
    q = (lo + hi) / 2;
    if t_cdf(q, gl) < p
      lo = q;
    else
      hi = q;
    end
  end
end

function c = t_cdf(x, gl)
  tail = 0.5 * betainc(gl / (gl + x^2), gl / 2, 0.5);
  if x >= 0
    c = 1 - tail;
  else
    c = tail;
  end
end
