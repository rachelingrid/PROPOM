function s = html_esc(s)
% HTML_ESC  Escapa &, < e > para exibir texto (ex.: codigo-fonte) em HTML.
  s = strrep(s, '&', '&amp;');
  s = strrep(s, '<', '&lt;');
  s = strrep(s, '>', '&gt;');
end
