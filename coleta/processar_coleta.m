function processar_coleta(codigo, opcoes)
% PROCESSAR_COLETA  Botão de processamento de uma coleta registrada.
% Normalmente aberto pelo menu:  propom
%
%  1. associa os CSVs de TERMOCSV\<código> às capturas registradas
%  2. processa as ROIs (propom_roi) -> RESULTADOS\<código>\termico
%  3. calcula UR e temperatura no momento de cada imagem (CSVs de TEMUR)
%  4. emite os relatórios parciais (fisiológico, ambiental, térmico) e o
%     relatório completo com as três páginas
%  5. atualiza as tabelas consolidadas em RESULTADOS

  aqui = fileparts(mfilename('fullpath'));
  addpath(fullfile(aqui, 'funcoes'));
  if nargin < 2, opcoes = struct(); end
  P = preparar_propom(opcoes);
  if nargin < 1 || isempty(codigo)
    codigo = escolher_coleta(P);
    if isempty(codigo), return; end
  end

  pA = fullfile(P.pasta.ANAMNESE, codigo);
  pC = fullfile(P.pasta.TERMOCSV, codigo);
  pJ = fullfile(P.pasta.TERMOJPG, codigo);
  pR = fullfile(P.pasta.RESULTADOS, codigo);
  if ~isfile(fullfile(pA, 'registro.csv')), error('Coleta %s não encontrada em ANAMNESE.', codigo); end
  if ~isfolder(pR), mkdir(pR); end
  printf('\n================ PROCESSANDO %s ================\n', codigo);

  [R, get] = ler_registro(fullfile(pA, 'registro.csv'));
  [~, lc] = ler_csv_texto(fullfile(pA, 'capturas.csv'));
  n = size(lc, 1);
  capt = struct('ordem', num2cell(str2double(lc(:,1))), 'condicao', lc(:,2), ...
                't', num2cell(cellfun(@parse_datahora, lc(:,3))));

  % ---------- 1. associação imagens x capturas ----------
  arqs = listar_arquivos(pC, {'*.csv', '*.CSV'});
  arqs = arqs(~strcmpi(arqs, 'protocolo.csv'));
  if numel(arqs) < n
    error('TERMOCSV\\%s tem %d CSVs; foram registradas %d capturas.', codigo, numel(arqs), n);
  end
  if numel(arqs) > n
    printf('  TERMOCSV\\%s tem %d CSVs; usarei os %d ÚLTIMOS pela ordem do nome.\n', codigo, numel(arqs), n);
    arqs = arqs(end-n+1:end);
  end
  jpgs = listar_arquivos(pJ, {'*.jpg', '*.JPG', '*.jpeg', '*.JPEG'});
  if numel(jpgs) ~= n
    printf('  AVISO: TERMOJPG\\%s tem %d JPGs para %d capturas.\n', codigo, numel(jpgs), n);
  end
  printf('  Associação (ordem do nome do arquivo = ordem de captura):\n');
  for k = 1:n
    printf('   %2d  %-14s %s  %s\n', k, capt(k).condicao, datestr(capt(k).t, 'HH:MM:SS'), arqs{k});
  end
  if ~perguntar_sn('  Associação correta'), printf('Processamento cancelado.\n'); return; end

  prot = fullfile(pR, 'protocolo.csv');
  fp = fopen(prot, 'w');
  fprintf(fp, 'participante,sessao,ordem,arquivo,condicao_protocolo,hora_captura\n');
  for k = 1:n
    fprintf(fp, '%s,S01,%d,%s,%s,%s\n', codigo, k, arqs{k}, capt(k).condicao, datestr(capt(k).t, 'HH:MM:SS'));
  end
  fclose(fp);

  % ---------- 2. ROIs ----------
  printf('\n  Processando ROIs...\n');
  pT = fullfile(pR, 'termico');
  propom_roi(pC, pT, prot);

  % ---------- 3. ambiente no momento de cada imagem ----------
  M = ler_temur(P.pasta.TEMUR);
  for a = M.avisos, printf('  AVISO TEMUR: %s\n', a{1}); end
  amb = struct('ordem', {}, 'condicao', {}, 't', {}, 'UR', {}, 'T', {}, 'status', {});
  fa = fopen(fullfile(pR, 'ambiente_por_imagem.csv'), 'w');
  fprintf(fa, 'codigo,ordem,arquivo,condicao,data_hora,UR_pct,T_C,UR_na_faixa,T_na_faixa,status,metodo\n');
  for k = 1:n
    [u, t, st] = ambiente_no_momento(M, capt(k).t, P);
    amb(k) = struct('ordem', k, 'condicao', capt(k).condicao, 't', capt(k).t, 'UR', u, 'T', t, 'status', st);
    fprintf(fa, '%s,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s\n', codigo, k, arqs{k}, capt(k).condicao, ...
            datestr(capt(k).t, 'yyyy-mm-dd HH:MM:SS'), nt(u, '%.2f'), nt(t, '%.3f'), ...
            faixa(u, P.UR_faixa_pct), faixa(t, P.T_faixa_C), st, P.temur_metodo);
  end
  fclose(fa);
  sem = sum(isnan([amb.UR]));
  if sem > 0
    printf('  AVISO: %d imagem(ns) sem UR/T (%s).\n', sem, amb(find(isnan([amb.UR]), 1)).status);
  else
    printf('  UR/T calculadas para as %d imagens.\n', n);
  end

  % ---------- 4. relatórios ----------
  info = identificacao(P, codigo);
  info.codigo = codigo;
  info.idade = get('idade_anos');
  info.data_coleta = datestr(capt(1).t, 'dd/mm/yyyy HH:MM');
  rel = struct('fisiologico', fullfile(pR, ['relatorio_parcial_fisiologico_' codigo '.pdf']), ...
               'ambiental',   fullfile(pR, ['relatorio_parcial_ambiental_'   codigo '.pdf']), ...
               'termico',     fullfile(pR, ['relatorio_parcial_termico_'     codigo '.pdf']), ...
               'completo',    fullfile(pR, ['relatorio_completo_'            codigo '.pdf']));
  if isfile(rel.completo), delete(rel.completo); end
  printf('\n  Emitindo relatórios...\n');
  completo_ok = true;
  paginas = {'fisiologico', 'ambiental', 'termico'};
  for i = 1:3
    switch paginas{i}
      case 'fisiologico', f = relatorio_fisiologico(info, R, pA, P);
      case 'ambiental',   f = relatorio_ambiental(info, get, amb, M, P);
      case 'termico',     f = relatorio_termico(info, pC, pT, P);
    end
    print(f, '-dpdf', rel.(paginas{i}));
    if completo_ok
      try
        if i == 1, print(f, '-dpdf', rel.completo);
        else,      print(f, '-dpdf', '-append', rel.completo); end
      catch err
        completo_ok = false;
        printf('  AVISO: não consegui montar o relatório completo (%s). Os parciais foram salvos.\n', err.message);
      end
    end
    close(f);
    printf('   %s\n', rel.(paginas{i}));
  end
  if completo_ok, printf('   %s\n', rel.completo); end

  % ---------- 5. registro e tabelas consolidadas ----------
  R = reg_add(R, 'status', 'Situação', 'processada');
  R = reg_add(R, 'data_processamento', 'Data do processamento', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
  salvar_registro(fullfile(pA, 'registro.csv'), R);
  consolidar_tabelas(P);

  printf('\n================ %s PROCESSADA ================\n', codigo);
  if completo_ok && isguirunning(), try, open(rel.completo); catch, end, end
end

function c = escolher_coleta(P)
  c = '';
  d = dir(P.pasta.ANAMNESE);
  d = d([d.isdir] & ~ismember({d.name}, {'.', '..', 'QUESTIONARIOS'}));
  cods = {}; st = {};
  for i = 1:numel(d)
    f = fullfile(P.pasta.ANAMNESE, d(i).name, 'registro.csv');
    if ~isfile(f), continue; end
    [~, get] = ler_registro(f);
    cods{end+1} = d(i).name; st{end+1} = get('status'); %#ok<AGROW>
  end
  if isempty(cods), printf('Nenhuma coleta registrada em %s\n', P.pasta.ANAMNESE); return; end
  printf('\nColetas registradas:\n');
  for i = 1:numel(cods), printf('  [%d] %-28s %s\n', i, cods{i}, st{i}); end
  s = perguntar_texto('Número da coleta a processar (0 = cancelar)', @(s) any(str2double(s) == 0:numel(cods)));
  k = str2double(s);
  if k > 0, c = cods{k}; end
end

function info = identificacao(P, codigo)
  info = struct('nome', '(não encontrado)', 'nascimento', '—', 'sexo', '—');
  f = fullfile(P.pasta.ANAMNESE, 'identificacao_PRIVADO.csv');
  if ~isfile(f), return; end
  [cab, lin] = ler_csv_texto(f);
  i = find(strcmp(lin(:, strcmp(cab, 'codigo')), codigo), 1, 'last');
  if isempty(i), return; end
  info.nome = lin{i, strcmp(cab, 'nome')};
  info.nascimento = lin{i, strcmp(cab, 'data_nascimento')};
  info.sexo = lin{i, strcmp(cab, 'sexo')};
end

function s = nt(x, f)
  if isfinite(x), s = sprintf(f, x); else, s = ''; end
end

function s = faixa(x, fx)
  if ~isfinite(x), s = ''; elseif x >= fx(1) && x <= fx(2), s = 's'; else, s = 'n'; end
end
