function ne = n_efetivo(n, rho1)
% N_EFETIVO  Tamanho amostral efetivo de uma serie AR(1).
%   ne = n (1 - rho1) / (1 + rho1), limitado ao intervalo [2, n].
%   Amostras vizinhas no tempo carregam informacao repetida; ne estima
%   quantas observacoes independentes a serie realmente contem.
  if rho1 <= 0
    ne = n;
  else
    ne = n * (1 - rho1) / (1 + rho1);
  end
  ne = max(2, min(n, ne));
end
