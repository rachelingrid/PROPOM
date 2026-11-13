function [T, integ] = ler_matriz_termica(arquivo, P)
% Etapas 1-2: lê a matriz em °C e confere integridade.
% Retira SOMENTE a coluna final vazia do exportador. Não substitui ausentes por zero,
% não suaviza, não interpola, não normaliza.

  integ = struct('arquivo', arquivo, 'ok', true, 'motivo', '', ...
                 'linhas_lidas', NaN, 'colunas_lidas', NaN, ...
                 'coluna_vazia_removida', false, 'n_ausentes', NaN, ...
                 'n_fora_faixa', NaN, 'Tmin', NaN, 'Tmax', NaN);

  txt = fileread(arquivo);
  txt = strrep(txt, sprintf('\r'), '');
  linhas = strsplit(strtrim(txt), sprintf('\n'));
  nl = numel(linhas);
  campos = strsplit(linhas{1}, ',', 'CollapseDelimiters', false);
  nc = numel(campos);
  T = NaN(nl, nc);
  for i = 1:nl
    c = strsplit(linhas{i}, ',', 'CollapseDelimiters', false);
    if numel(c) ~= nc
      integ.ok = false;
      integ.motivo = sprintf('linha %d com %d campos (esperado %d)', i, numel(c), nc);
      T = []; return;
    end
    v = str2double(c);          % campo vazio ou não numérico -> NaN (nunca zero)
    T(i, :) = v;
  end
  integ.linhas_lidas  = nl;
  integ.colunas_lidas = nc;

  % coluna vazia do exportador: apenas a ÚLTIMA, e só se estiver inteiramente vazia
  if nc == P.n_colunas + 1 && all(isnan(T(:, end)))
    T = T(:, 1:end-1);
    integ.coluna_vazia_removida = true;
  end

  if ~isequal(size(T), [P.n_linhas P.n_colunas])
    integ.ok = false;
    integ.motivo = sprintf('dimensão %dx%d (esperado %dx%d)', size(T,1), size(T,2), P.n_linhas, P.n_colunas);
    return;
  end

  integ.n_ausentes   = sum(isnan(T(:)));
  fora = T < P.faixa_valida_C(1) | T > P.faixa_valida_C(2);
  integ.n_fora_faixa = sum(fora(:));
  integ.Tmin = min(T(:));  integ.Tmax = max(T(:));
  if integ.n_ausentes > 0
    integ.ok = false; integ.motivo = sprintf('%d valores ausentes/inválidos', integ.n_ausentes);
  elseif integ.n_fora_faixa > 0
    integ.ok = false; integ.motivo = sprintf('%d valores fora de %g-%g °C', integ.n_fora_faixa, P.faixa_valida_C);
  end
end
