function r = perguntar_sn(msg)
% Pergunta sim/não até obter resposta válida.
  while true
    s = lower(strtrim(input([msg ' (s/n): '], 's')));
    if any(strcmp(s, {'s','sim'})), r = true; return; end
    if any(strcmp(s, {'n','nao','não'})), r = false; return; end
    printf('  Responda s ou n.\n');
  end
end
