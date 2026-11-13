function [ur, tc, st] = ambiente_no_momento(M, t, P)
% UR (%) e temperatura (°C) no instante t (datenum), a partir das leituras
% do termo-higrômetro (M de ler_temur).
%  - leitura no mesmo horário (±1 s): usa essa leitura
%  - entre duas leituras: P.temur_metodo
%       'media_vizinhos' -> média da anterior e da posterior
%       'linear'         -> interpolação linear no tempo
%  - sem leitura anterior ou posterior, ou vizinhas afastadas mais de
%    P.temur_intervalo_max_min: sem valor (NaN). Nunca extrapola.
  ur = NaN; tc = NaN;
  if isempty(M.t), st = 'sem dados do termo-higrometro'; return; end
  ig = find(abs(M.t - t) <= 1/86400, 1);
  if ~isempty(ig), ur = M.UR(ig); tc = M.T(ig); st = 'ok'; return; end
  ia = find(M.t < t, 1, 'last'); ip = find(M.t > t, 1, 'first');
  if isempty(ia), st = 'antes da primeira leitura'; return; end
  if isempty(ip), st = 'depois da ultima leitura (exporte o CSV apos a coleta)'; return; end
  gap = (M.t(ip) - M.t(ia)) * 1440;
  if gap > P.temur_intervalo_max_min
    st = sprintf('leituras vizinhas a %.0f min uma da outra', gap); return;
  end
  if strcmp(P.temur_metodo, 'linear')
    w = (t - M.t(ia)) / (M.t(ip) - M.t(ia));
    ur = M.UR(ia) + w * (M.UR(ip) - M.UR(ia));
    tc = M.T(ia)  + w * (M.T(ip)  - M.T(ia));
  else
    ur = (M.UR(ia) + M.UR(ip)) / 2;
    tc = (M.T(ia)  + M.T(ip))  / 2;
  end
  st = 'ok';
end
