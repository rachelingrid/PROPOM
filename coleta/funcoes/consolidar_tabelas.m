function consolidar_tabelas(P)
% Reconstrói as tabelas consolidadas em RESULTADOS a partir de todas as
% coletas (refazer um processamento nunca duplica linhas).
%  coletas_consolidado.csv       1 linha por coleta (registro + ambiente no momento da coleta)
%  rois_consolidado.csv          1 linha por imagem e olho (ROI, 7 medidas, UR e T da imagem)
%  questionarios_consolidado.csv codigo, campo, valor
% Nenhuma delas contém nome ou data de nascimento.

  d = dir(P.pasta.ANAMNESE);
  d = d([d.isdir] & ~ismember({d.name}, {'.', '..', 'QUESTIONARIOS'}));
  chaves = {}; regs = {};
  rois_cab = {}; rois = {};
  qs = cell(0, 3);
  for i = 1:numel(d)
    cod = d(i).name;
    fr = fullfile(P.pasta.ANAMNESE, cod, 'registro.csv');
    if ~isfile(fr), continue; end
    R = ler_registro(fr);
    % ambiente no momento da coleta (1ª imagem) e por condição
    fa = fullfile(P.pasta.RESULTADOS, cod, 'ambiente_por_imagem.csv');
    if isfile(fa)
      [ca, la] = ler_csv_texto(fa);
      u = str2double(la(:, strcmp(ca, 'UR_pct'))); t = str2double(la(:, strcmp(ca, 'T_C')));
      cnd = la(:, strcmp(ca, 'condicao'));
      R = reg_add(R, 'UR_coleta_pct', '', nt(u(1)));
      R = reg_add(R, 'T_coleta_C', '', nt(t(1)));
      for c = {'aberto', 'fechado'}
        s = strcmp(cnd, c{1});
        R = reg_add(R, ['UR_media_' c{1} '_pct'], '', nt(mean(u(s))));
        R = reg_add(R, ['T_media_' c{1} '_C'], '', nt(mean(t(s))));
      end
      % ROIs desta coleta + UR/T da imagem
      fx = fullfile(P.pasta.RESULTADOS, cod, 'termico', 'resultados_individuais.csv');
      if isfile(fx)
        [cx, lx] = ler_csv_texto(fx);
        ord = str2double(lx(:, strcmp(cx, 'ordem')));
        lx = [lx, arrayfun(@(o) nt(u(o)), ord, 'UniformOutput', false), ...
                  arrayfun(@(o) nt(t(o)), ord, 'UniformOutput', false)];
        rois_cab = [cx, {'UR_imagem_pct', 'T_imagem_C'}];
        rois = [rois; lx]; %#ok<AGROW>
      end
    end
    for k = 1:size(R, 1)
      if ~any(strcmp(chaves, R{k,1})), chaves{end+1} = R{k,1}; end %#ok<AGROW>
    end
    regs{end+1} = R; %#ok<AGROW>
    fq = fullfile(P.pasta.ANAMNESE, cod, 'questionario.csv');
    if isfile(fq)
      [~, lq] = ler_csv_texto(fq);
      qs = [qs; [repmat({cod}, size(lq, 1), 1), lq(:, 1:2)]]; %#ok<AGROW>
    end
  end

  escrever(fullfile(P.pasta.RESULTADOS, 'coletas_consolidado.csv'), chaves, ...
           cellfun(@(R) linha(R, chaves), regs, 'UniformOutput', false));
  if ~isempty(rois)
    escrever(fullfile(P.pasta.RESULTADOS, 'rois_consolidado.csv'), rois_cab, num2cell(rois, 2)');
  end
  escrever(fullfile(P.pasta.RESULTADOS, 'questionarios_consolidado.csv'), {'codigo','campo','valor'}, ...
           num2cell(qs, 2)');
end

function v = linha(R, chaves)
  v = cell(1, numel(chaves));
  for k = 1:numel(chaves)
    i = find(strcmp(R(:,1), chaves{k}), 1);
    if isempty(i), v{k} = ''; else, v{k} = R{i,3}; end
    if isnumeric(v{k}), v{k} = num2str(v{k}); end
  end
end

function escrever(arq, cab, linhas)
  fid = fopen(arq, 'w');
  if fid < 0, printf('  AVISO: não consegui gravar %s (aberto no Excel?)\n', arq); return; end
  fprintf(fid, '%s\n', strjoin(cellfun(@campo_csv, cab, 'UniformOutput', false), ','));
  for i = 1:numel(linhas)
    l = cellfun(@campo_csv, linhas{i}, 'UniformOutput', false);
    fprintf(fid, '%s\n', strjoin(l, ','));
  end
  fclose(fid);
end

function s = nt(x)
  if isfinite(x), s = sprintf('%.4g', x); else, s = ''; end
end
