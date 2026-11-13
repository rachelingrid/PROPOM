function C = classificar_palpebra(T, R, lado, visor_util, P)
% Etapa 4 (EXPLORATÓRIA, ainda não validada): estado palpebral pela geometria
% da fenda palpebral.
% Mede, ao longo do eixo intercantal e lateralmente ao endocanto, a diferença
% entre a faixa da fenda palpebral (|v| <= 1,5 px) e a faixa da pálpebra
% superior (v entre 3 e 7 px acima). Enquanto P.limiar_palpebral estiver
% vazio, a classe é sempre 'indeterminado' e só o índice é registrado.
% Esta função NÃO altera a região orbital, que é a mesma com olhos abertos
% ou fechados.

  O = R.(lado);
  desloc = R.a_px - P.orbita_medial_mm / P.mm_por_px;   % u do endocanto
  faixa_u = O.u <= desloc - 3 & O.u >= desloc - 12;
  fenda = faixa_u & abs(O.v) <= 1.5 & visor_util;
  palp  = faixa_u & O.v >= 3 & O.v <= 7 & visor_util;

  C.n_fenda = sum(fenda(:)); C.n_palpebra = sum(palp(:));
  if C.n_fenda < 5 || C.n_palpebra < 5
    C.indice = NaN; C.classe = 'indeterminado'; return;
  end
  C.indice = mean(T(fenda)) - mean(T(palp));

  if isempty(P.limiar_palpebral)
    C.classe = 'indeterminado';
  elseif C.indice < P.limiar_palpebral(1)
    C.classe = 'aberto';
  elseif C.indice > P.limiar_palpebral(end)
    C.classe = 'fechado';
  else
    C.classe = 'indeterminado';
  end
end
