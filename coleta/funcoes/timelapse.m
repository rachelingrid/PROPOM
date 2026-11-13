function t = timelapse(n, condicao, intervalo)
% Orienta a captura: bipe + aviso a cada 'intervalo' s. Retorna o horário
% programado de cada imagem. A captura é feita na câmera pela operadora.
  printf('\n>>> %s: %d imagens, uma a cada %g s. Pressione Enter para começar.', upper(condicao), n, intervalo);
  input('', 's');
  t = zeros(1, n);
  for k = 1:n
    if k > 1
      for r = intervalo:-1:1
        printf('\r    próxima em %2d s ', r); fflush(stdout); pause(1 * (intervalo > 0));
      end
    end
    t(k) = now; beep();
    printf('\r    >>> CAPTURE AGORA: imagem %d/%d (%s)  [%s]\n', k, n, condicao, datestr(t(k), 'HH:MM:SS'));
  end
end
