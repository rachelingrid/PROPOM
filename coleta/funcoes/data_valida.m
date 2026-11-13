function ok = data_valida(s)
% dd/mm/aaaa, data real e no passado
  ok = false;
  t = regexp(s, '^(\d{2})/(\d{2})/(\d{4})$', 'tokens', 'once');
  if isempty(t), return; end
  d = str2double(t{1}); m = str2double(t{2}); a = str2double(t{3});
  if m < 1 || m > 12 || a < 1900, return; end
  if d < 1 || d > eomday(a, m), return; end
  ok = datenum(a, m, d) < now;
end
