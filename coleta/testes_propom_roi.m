function testes_propom_roi(pasta_dados, pasta_saida)
% Etapa 12: validação automática do pipeline no Octave.
%   1. leitura/integridade (casos sintéticos)
%   2. seleção 3x3 e as sete medidas (caso sintético com resposta conhecida)
%   3. dados reais: janela 100% dentro da máscara elegível, medidas
%      recalculadas a partir do CSV bruto, quadrante correto
%   4. reprodutibilidade (segunda execução idêntica)
%   5. relatório exploratório do índice palpebral por condição do protocolo
% Uso: testes_propom_roi('dados', 'saida')   (rode propom_roi antes)

  if nargin < 1, pasta_dados = 'dados'; end
  if nargin < 2, pasta_saida = 'saida'; end
  aqui = fileparts(mfilename('fullpath'));
  addpath(fullfile(aqui, 'funcoes'));
  P = config_propom();
  nf = 0; np = 0;
  tmp = tempname(); mkdir(tmp);

  % ---------- 1. leitura e integridade ----------
  M = 22 + rand(240, 320);
  f = fullfile(tmp, 'ok.csv');      grava(f, M, true);
  [T, I] = ler_matriz_termica(f, P);
  [np, nf] = verifica(np, nf, I.ok && I.coluna_vazia_removida && isequal(size(T), [240 320]), ...
                      'CSV válido 240x321 com coluna final vazia');
  [np, nf] = verifica(np, nf, max(abs(T(:) - round(M(:)*100)/100)) < 1e-9, 'valores preservados sem alteração');
  M2 = M; M2(10, 20) = NaN; f = fullfile(tmp, 'ausente.csv'); grava(f, M2, true);
  [T, I] = ler_matriz_termica(f, P);
  [np, nf] = verifica(np, nf, ~I.ok && isnan(T(10,20)), 'valor ausente detectado e NÃO trocado por zero');
  f = fullfile(tmp, 'dim.csv'); grava(f, M(:, 1:300), true);
  [~, I] = ler_matriz_termica(f, P);
  [np, nf] = verifica(np, nf, ~I.ok, 'dimensão incorreta rejeitada');
  f = fullfile(tmp, 'semvazia.csv'); grava(f, M, false);
  [T, I] = ler_matriz_termica(f, P);
  [np, nf] = verifica(np, nf, I.ok && ~I.coluna_vazia_removida && size(T,2) == 320, ...
                      'sem coluna vazia: nada é removido');

  % ---------- 2. janela 3x3 sintética ----------
  T = 30 + zeros(40);
  E = false(40); E(10:20, 10:20) = true;
  T(14:16, 15:17) = [34 35 34; 35 36 35; 34 35 34];   % quente, dentro da máscara
  T(1:3, 1:3) = 40;                                    % mais quente, FORA da máscara
  T(19:21, 19:21) = 39;                                % parcialmente fora -> não pode ganhar
  J = selecionar_janela_3x3(T, E);
  w = [34 35 34 35 36 35 34 35 34];
  [np, nf] = verifica(np, nf, J.linha_centro == 15 && J.coluna_centro == 16, ...
                      'escolhe a maior média só entre janelas inteiramente na máscara');
  ok = abs(J.maximo-36)<1e-12 && abs(J.minimo-34)<1e-12 && abs(J.media-mean(w))<1e-12 && ...
       abs(J.mediana-35)<1e-12 && abs(J.desvio_padrao-std(w))<1e-12 && ...
       abs(J.variancia-var(w))<1e-12 && abs(J.amplitude-2)<1e-12;
  [np, nf] = verifica(np, nf, ok, 'sete medidas corretas nos nove pixels');
  [np, nf] = verifica(np, nf, abs(J.variancia - sum((w-mean(w)).^2)/8) < 1e-12, 'variância amostral (n-1 = 8)');

  % ---------- 3. dados reais ----------
  [cab, lin] = ler_csv_texto(fullfile(pasta_saida, 'resultados_individuais.csv'));
  col = @(n) lin(:, strcmp(cab, n));
  arqs = col('arquivo'); lados = col('olho');
  r = str2double(col('linha_centro')); c = str2double(col('coluna_centro'));
  med = {'maximo','minimo','media','mediana','desvio_padrao','variancia','amplitude'};
  dentro = true; recalc = true; quadr = true; pixels = true;
  for i = 1:numel(arqs)
    T = ler_matriz_termica(fullfile(pasta_dados, arqs{i}), P);
    [~, b] = fileparts(arqs{i});
    S = load(fullfile(pasta_saida, 'mascaras', [b '.mat']));
    id = lados{i};
    Eg = S.(['elegivel_' id]); Q = S.(['quadrantes_' id]);
    blk = Eg(r(i)-1:r(i)+1, c(i)-1:c(i)+1);  dentro = dentro && all(blk(:));
    qb  = Q(r(i)-1:r(i)+1, c(i)-1:c(i)+1);   quadr  = quadr && all(qb(:) == 1);
    W = T(r(i)-1:r(i)+1, c(i)-1:c(i)+1); w = W(:);
    ref = [max(w) min(w) mean(w) median(w) std(w) var(w) max(w)-min(w)];
    for q = 1:7
      recalc = recalc && abs(str2double(lin{i, strcmp(cab, med{q})}) - ref(q)) < 5e-4;
    end
    vs = str2double(lin(i, find(strcmp(cab, 'v11')):find(strcmp(cab, 'v33'))));
    pixels = pixels && max(abs(vs(:) - w)) < 1e-9;
    % nenhuma janela elegível tem média maior que a escolhida
    Tz = T; Tz(~Eg) = 0; mm = conv2(Tz, ones(3), 'same')/9; mm(conv2(double(Eg), ones(3), 'same') < 9) = -Inf;
    recalc = recalc && abs(max(mm(:)) - mean(w)) < 1e-9;
  end
  [np, nf] = verifica(np, nf, dentro, sprintf('%d janelas reais 100%% dentro da pele elegível', numel(arqs)));
  [np, nf] = verifica(np, nf, quadr,  'todas no quadrante superior medial');
  [np, nf] = verifica(np, nf, pixels, 'os nove valores salvos são os da matriz original');
  [np, nf] = verifica(np, nf, recalc, 'medidas e máxima média recalculadas do CSV bruto conferem');

  % lateralidade anatômica: participante de frente -> OD à esquerda da imagem
  cOD = c(strcmp(lados, 'OD')); cOE = c(strcmp(lados, 'OE'));
  NC  = str2double(col('N_col'));
  lado_ok = numel(cOD) == numel(cOE) && all(cOD < cOE) && ...
            all(cOD < NC(strcmp(lados, 'OD'))) && all(cOE > NC(strcmp(lados, 'OE')));
  if strcmp(P.espelhamento, 'espelhada'), lado_ok = all(cOD > cOE); end
  [np, nf] = verifica(np, nf, lado_ok, 'OD à esquerda e OE à direita do dorso nasal na imagem (participante de frente)');

  % ambiente: média das leituras vizinhas (exemplo do protocolo)
  Mt = struct('t', datenum(2026,11,12,10,[0 10],0)', 'UR', [40; 41], 'T', [23.0; 23.4]);
  Pa = P; Pa.temur_metodo = 'media_vizinhos';
  [u, t2, st] = ambiente_no_momento(Mt, datenum(2026,11,12,10,6,0), Pa);
  [np, nf] = verifica(np, nf, abs(u-40.5) < 1e-12 && abs(t2-23.2) < 1e-12 && strcmp(st, 'ok'), ...
                      'UR/T às 10:06 entre leituras de 10:00 e 10:10 = média (40,5 %; 23,2 °C)');
  [u, ~, st] = ambiente_no_momento(Mt, datenum(2026,11,12,10,20,0), Pa);
  [np, nf] = verifica(np, nf, isnan(u) && ~strcmp(st, 'ok'), 'horário sem leitura posterior -> sem valor (não extrapola)');
  [u, ~] = ambiente_no_momento(Mt, datenum(2026,11,12,10,10,0), Pa);
  [np, nf] = verifica(np, nf, u == 41, 'horário exato da leitura -> valor da leitura');

  % código do participante
  cod = codigo_participante('Ana de Souza Lima', '05/07/1990', 'f', datenum(2026,11,12,10,6,0));
  cod1 = codigo_participante('Ana', '05/07/1990', 'F', datenum(2026,11,12,10,6,0));
  [np, nf] = verifica(np, nf, strcmp(cod, '05071990ASF_20261112-1006') && strcmp(cod1, '05071990A*F_20261112-1006'), ...
                      'código pseudonimizado (ignora "de", nome único -> *)');

  % ---------- 4. reprodutibilidade ----------
  s2 = fullfile(tmp, 'saida2');
  evalc('propom_roi(pasta_dados, s2);');
  a = fileread(fullfile(pasta_saida, 'resultados_individuais.csv'));
  b = fileread(fullfile(s2, 'resultados_individuais.csv'));
  [np, nf] = verifica(np, nf, strcmp(a, b), 'segunda execução produz resultado idêntico');

  % ---------- 5. índice palpebral (exploratório) ----------
  cond = col('condicao_protocolo'); idx = str2double(col('indice_palpebral'));
  printf('\nÍndice palpebral (fenda - pálpebra superior, °C) por condição do PROTOCOLO:\n');
  for l = {'OD', 'OE'}
    for k = {'aberto', 'fechado'}
      s = strcmp(lados, l{1}) & strcmp(cond, k{1});
      printf('  %-3s %-8s  %s\n', l{1}, k{1}, sprintf('%6.3f ', idx(s)));
    end
    xa = idx(strcmp(lados, l{1}) & strcmp(cond, 'aberto'));
    xf = idx(strcmp(lados, l{1}) & strcmp(cond, 'fechado'));
    sep = max(xa) < min(xf) || max(xf) < min(xa);
    printf('  -> separação completa entre condições: %s\n', ifelse(sep, 'SIM (n=5+5, insuficiente para validar)', 'NÃO'));
  end

  printf('\n%d testes aprovados, %d reprovados.\n', np, nf);
  confirm_recursive_rmdir(false); rmdir(tmp, 's');
  if nf > 0, error('Há testes reprovados.'); end
end

function [np, nf] = verifica(np, nf, cond, nome)
  if cond, np = np + 1; printf('  [OK]    %s\n', nome);
  else,    nf = nf + 1; printf('  [FALHA] %s\n', nome); end
end

function grava(f, M, vazia)
  fid = fopen(f, 'w');
  for i = 1:size(M, 1)
    s = sprintf('%.2f,', M(i, :)); s = strrep(s, 'NaN', '');
    if ~vazia, s = s(1:end-1); end
    fprintf(fid, '%s\n', s);
  end
  fclose(fid);
end

function r = ifelse(c, a, b)
  if c, r = a; else, r = b; end
end
