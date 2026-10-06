function [x, y, t_h] = recortar_janela(tn, xs, ys, inicio, duracao_min)
% RECORTAR_JANELA  Extrai uma janela continua de 1 amostra/min de uma serie de logger.
%   inicio      : 'AAAA-MM-DD hh:mm'
%   duracao_min : duracao em minutos (a janela tem duracao_min + 1 amostras)
%   t_h         : tempo desde o inicio da janela, em horas
%   Gera erro se faltar qualquer minuto dentro da janela.
  t0 = datenum(inicio, 'yyyy-mm-dd HH:MM');
  alvo = round(t0 * 1440) + (0:duracao_min)';
  [ok, idx] = ismember(alvo, round(tn * 1440));
  if ~all(ok)
    error('Janela iniciada em %s: faltam %d de %d minutos nos dados.', inicio, sum(~ok), numel(ok));
  end
  x = xs(idx);
  y = ys(idx);
  t_h = (0:duracao_min)' / 60;
end
