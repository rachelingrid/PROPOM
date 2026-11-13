function [A, ok, desvio] = checar_faixa(P, momento)
% Lê o ambiente e confere as faixas. Fora da faixa: reler, continuar com
% desvio registrado, ou encerrar (ok = false).
  desvio = '';
  while true
    A = ler_ambiente(P, momento);
    urOK = A.UR >= P.UR_faixa_pct(1) && A.UR <= P.UR_faixa_pct(2);
    tOK  = A.T  >= P.T_faixa_C(1)    && A.T  <= P.T_faixa_C(2);
    printf('  UR = %.1f %% [%g–%g] %s | T = %.2f °C [%g–%g] %s\n', A.UR, P.UR_faixa_pct, ...
           ok_txt(urOK), A.T, P.T_faixa_C, ok_txt(tOK));
    if urOK && tOK, ok = true; return; end
    op = lower(perguntar_texto('  Fora da faixa: [r]eler, [c]ontinuar registrando desvio, [e]ncerrar', ...
               @(s) any(strcmpi(s, {'r','c','e'}))));
    switch op
      case 'c'
        ok = true;
        desvio = strjoin([repmat({'UR fora da faixa'}, 1, ~urOK) repmat({'T fora da faixa'}, 1, ~tOK)], '; ');
        return;
      case 'e'
        ok = false; return;
    end
  end
end
function s = ok_txt(x)
  if x, s = 'OK'; else, s = 'FORA'; end
end
