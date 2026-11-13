function P = preparar_propom(opcoes)
% Carrega a configuração, aplica sobrescritas (struct opcional) e cria as
% pastas predefinidas dentro de P.raiz.
  P = config_propom();
  if nargin >= 1 && isstruct(opcoes)
    for k = fieldnames(opcoes)', P.(k{1}) = opcoes.(k{1}); end
  end
  P.pasta.TEMUR       = fullfile(P.raiz, 'TEMUR');
  P.pasta.TERMOCSV    = fullfile(P.raiz, 'TERMOCSV');
  P.pasta.TERMOJPG    = fullfile(P.raiz, 'TERMOJPG');
  P.pasta.ANAMNESE    = fullfile(P.raiz, 'ANAMNESE');
  P.pasta.QUESTIONARIOS = fullfile(P.raiz, 'ANAMNESE', 'QUESTIONARIOS');
  P.pasta.RESULTADOS  = fullfile(P.raiz, 'RESULTADOS');
  for k = fieldnames(P.pasta)'
    if ~isfolder(P.pasta.(k{1})), mkdir(P.pasta.(k{1})); end
  end
end
