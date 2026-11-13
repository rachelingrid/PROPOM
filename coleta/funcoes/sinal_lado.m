function s = sinal_lado(olho, P)
% Lado da IMAGEM em que o olho aparece, em relação ao dorso nasal:
% -1 = à esquerda na imagem, +1 = à direita.
% Participante de frente (sem espelhamento): OD à esquerda, OE à direita.
  s = -1;
  if strcmp(olho, 'OE'), s = 1; end
  if strcmp(P.espelhamento, 'espelhada'), s = -s; end
end
