function propom(opcoes)
% PROPOM  Menu principal da coleta ProPOM.
%
% No Octave, dentro desta pasta, digite:   propom
%
%   [Nova coleta]                     registra ambiente, checklist, participante,
%                                     biometria, sinais vitais, questionário e captura
%   [Processar coleta e emitir        processa as imagens, calcula UR/T no momento
%    relatório completo]              de cada imagem e emite os relatórios
%   [Sair]

  aqui = fileparts(mfilename('fullpath'));
  addpath(fullfile(aqui, 'funcoes'));
  if nargin < 1, opcoes = struct(); end
  P = preparar_propom(opcoes);
  printf('\nProPOM — dados em: %s\n', P.raiz);
  while true
    op = menu_propom('ProPOM', 'Nova coleta', 'Processar coleta e emitir relatório completo', 'Sair');
    switch op
      case 1
        cod = coleta_propom(opcoes);
        if ~isempty(cod) && perguntar_sn(sprintf('\nOs arquivos da câmera e do termo-higrômetro já estão nas pastas e quer processar agora'))
          processar_coleta(cod, opcoes);
        end
      case 2
        processar_coleta('', opcoes);
      otherwise
        break;
    end
  end
end
