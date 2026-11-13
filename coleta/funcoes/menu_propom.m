function op = menu_propom(titulo, varargin)
% Menu de botões. Na interface gráfica do Octave abre uma janela com as
% opções; no terminal (ou se a janela falhar) mostra opções numeradas.
  op = 0;
  if isguirunning()
    try
      op = menu(titulo, varargin{:});
      return;
    catch
    end
  end
  printf('\n----- %s -----\n', titulo);
  for k = 1:numel(varargin), printf('  [%d] %s\n', k, varargin{k}); end
  s = perguntar_texto('Escolha', @(s) any(str2double(s) == 1:numel(varargin)));
  op = str2double(s);
end
