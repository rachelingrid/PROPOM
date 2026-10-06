function sombrear_faixas(faixas, yl, C, rotular, margem, alternar)
% SOMBREAR_FAIXAS  Sombreia intervalos do eixo x (fases, janelas) no eixo atual.
%   faixas  : struct com campos ini, fim e nome
%   yl      : limites verticais [ymin ymax]
%   rotular : escreve o nome no topo de cada faixa (padrao: true)
%   margem  : quanto estender cada faixa para os lados (padrao: 0,5 = meio quadro)
%   alternar: alterna sombreado/branco entre faixas vizinhas (padrao: true)
  if nargin < 4, rotular = true; end
  if nargin < 5, margem = 0.5; end
  if nargin < 6, alternar = true; end
  hold on;
  for k = 1:numel(faixas)
    x0 = faixas(k).ini - margem;  x1 = faixas(k).fim + margem;
    if ~alternar || mod(k, 2) == 1, cor = C.faixa; else, cor = [1 1 1]; end
    patch([x0 x1 x1 x0], [yl(1) yl(1) yl(2) yl(2)], cor, 'edgecolor', 'none');
    if rotular
      text((x0 + x1) / 2, yl(2) - 0.04 * diff(yl), faixas(k).nome, 'horizontalalignment', 'center', ...
           'verticalalignment', 'top', 'color', C.sec, 'fontsize', 8);
    end
  end
  ylim(yl);
  hold off;
end
