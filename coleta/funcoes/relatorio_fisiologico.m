function f = relatorio_fisiologico(info, R, pasta_anamnese, P)
% Relatório parcial fisiológico: checklist do dia da coleta, dados
% biométricos, sinais vitais e resultado do questionário de autodeclaração
% de cognição. R = registro da coleta (cell N x 3: chave, descrição, valor).

  get = @(k) valor(R, k);
  [f, ax, txt, y] = relatorio_base('Relatório parcial fisiológico', info);

  % ---------- checklist ----------
  y = secao_relatorio(txt, ax, y, 'Checklist do dia da coleta');
  ks = R(strncmp(R(:,1), 'checklist_', 10), :);
  for i = 1:size(ks, 1)
    ok = strcmp(ks{i,3}, 's');
    r = 'Sim'; cor = [0 0 0]; if ~ok, r = 'NÃO'; cor = [0.75 0 0]; end
    txt(0.08, y, ks{i,2}, 'fontsize', 9.5);
    txt(0.80, y, r, 'fontsize', 9.5, 'fontweight', 'bold', 'color', cor);
    y = y - 0.018;
  end
  txt(0.08, y, sprintf('Aclimatado às %s', get('hora_aclimatado')), 'fontsize', 8.5, 'color', [.3 .3 .3]);
  y = y - 0.035;

  % ---------- biometria ----------
  y = secao_relatorio(txt, ax, y, 'Dados biométricos');
  campos = [P.biometria(:, 1)' {'IMC_kgm2'}];
  y = campos_em_duas_colunas(txt, R, campos, y);
  y = y - 0.025;

  % ---------- sinais vitais ----------
  y = secao_relatorio(txt, ax, y, sprintf('Sinais vitais (%s)', get('hora_sinais_vitais')));
  y = campos_em_duas_colunas(txt, R, P.sinais_vitais(:, 1)', y);
  y = y - 0.025;

  % ---------- questionário ----------
  y = secao_relatorio(txt, ax, y, 'Questionário de autodeclaração de cognição');
  resp = 'Não'; if strcmp(get('questionario_respondido'), 's'), resp = 'Sim'; end
  txt(0.08, y, sprintf('Respondido: %s', resp), 'fontsize', 9.5);
  arq = get('questionario_arquivo'); if isempty(arq), arq = 'não importado'; end
  txt(0.35, y, sprintf('Arquivo: %s', arq), 'fontsize', 9, 'color', [.3 .3 .3]);
  y = y - 0.019;
  if ~isempty(get('questionario_anotacao'))
    txt(0.08, y, sprintf('Anotação: %s', get('questionario_anotacao')), 'fontsize', 9.5);
    y = y - 0.019;
  end
  fq = fullfile(pasta_anamnese, 'questionario.csv');
  if isfile(fq)
    [~, lq] = ler_csv_texto(fq);
    vagas = max(0, floor((y - 0.17) / 0.0165));          % linhas que cabem até o rodapé
    n = size(lq, 1); por_col = ceil(min(n, 2*vagas) / 2);
    for i = 1:min(n, 2*vagas)
      c = ceil(i / por_col); yy = y - (i - (c-1)*por_col - 1) * 0.0165;
      x0 = 0.08 + (c-1)*0.44;
      txt(x0, yy, encurtar(lq{i,1}, 30), 'fontsize', 8.5, 'color', [.3 .3 .3]);
      txt(x0 + 0.28, yy, encurtar(lq{i,2}, 18), 'fontsize', 8.5, 'fontweight', 'bold');
    end
    y = y - por_col * 0.0165;
    if n > 2*vagas
      txt(0.08, y, sprintf('(+ %d campos em ANAMNESE\\%s\\questionario.csv)', n - 2*vagas, info.codigo), 'fontsize', 8);
      y = y - 0.0165;
    end
  end
  y = y - 0.02;

  % ---------- desvios e observações ----------
  d = get('desvios'); o = get('observacoes');
  if ~isempty(d) || ~isempty(o)
    y = secao_relatorio(txt, ax, y, 'Desvios e observações');
    if ~isempty(d), txt(0.08, y, ['Desvios: ' d], 'fontsize', 9.5, 'color', [0.75 0 0]); y = y - 0.019; end
    if ~isempty(o), txt(0.08, y, ['Observações: ' o], 'fontsize', 9.5); end
  end

  rodape_relatorio(txt, ax, {'Campos em branco (—) não foram medidos ou informados.'});
end

function y = campos_em_duas_colunas(txt, R, chaves, y)
  n = numel(chaves); por_col = ceil(n / 2);
  for i = 1:n
    c = ceil(i / por_col); yy = y - (i - (c-1)*por_col - 1) * 0.019;
    x0 = 0.08 + (c-1)*0.44;
    j = find(strcmp(R(:,1), chaves{i}), 1);
    if isempty(j), rot = chaves{i}; v = ''; else, rot = R{j,2}; v = R{j,3}; end
    if isnumeric(v), v = num2str(v); end
    if isempty(v), v = '—'; end
    txt(x0, yy, rot, 'fontsize', 9.5, 'color', [.25 .25 .25]);
    txt(x0 + 0.30, yy, v, 'fontsize', 9.5, 'fontweight', 'bold');
  end
  y = y - por_col * 0.019;
end

function v = valor(R, k)
  i = find(strcmp(R(:,1), k), 1);
  v = ''; if ~isempty(i), v = R{i,3}; end
  if isnumeric(v), v = num2str(v); end
end

function s = encurtar(s, n)
  if numel(s) > n, s = [s(1:n-1) '…']; end
end
