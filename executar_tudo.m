% EXECUTAR_TUDO  Roda todas as analises do ProPOM e gera a pagina em ./site
%
%   No computador (offline):  abra o Octave nesta pasta e digite  executar_tudo
%                             depois abra site/index.html no navegador.
%   No GitHub:                o mesmo script e executado automaticamente a cada
%                             envio (.github/workflows/pagina.yml) e o resultado
%                             e publicado no GitHub Pages.
%
%   Requer apenas o GNU Octave (sem pacotes adicionais).

raiz = fileparts(mfilename('fullpath'));
if isempty(raiz), raiz = pwd; end
addpath(fullfile(raiz, 'lib'));

% Graficos sem abrir janelas (qt quando ha suporte grafico; gnuplot no modo texto)
tk = available_graphics_toolkits();
if any(strcmp(tk, 'qt'))
  graphics_toolkit('qt');
else
  graphics_toolkit('gnuplot');
end
set(0, 'defaultfigurevisible', 'off');

gerar_site(raiz);
