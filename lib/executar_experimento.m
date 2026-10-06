function R = executar_experimento(pasta_exp, pasta_saida) %#ok<INUSD>
% EXECUTAR_EXPERIMENTO  Roda experimentos/<nome>/analise.m num espaco de trabalho isolado.
%   O script analise.m roda com a pasta do experimento como diretorio corrente
%   e tem acesso a variavel pasta_saida (onde salva figuras e CSVs).
%   Ele deve preencher a struct R (ver experimentos/_modelo/analise.m).
  R = struct();
  run(fullfile(pasta_exp, 'analise.m'));
end
