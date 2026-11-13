function codigo = coleta_propom(opcoes)
% COLETA_PROPOM  Registro da coleta (sem processamento).
% Normalmente aberto pelo menu:  propom
%
% Etapas: ambiente -> checklist -> aclimatação -> participante -> biometria
% -> sinais vitais -> questionário -> orientação/posicionamento -> captura
% 5 olhos abertos + 5 olhos fechados (+ tomadas extras).
% Tudo é gravado em ANAMNESE\<código>\ a cada etapa. O processamento e os
% relatórios ficam no botão "Processar coleta" (processar_coleta).

  aqui = fileparts(mfilename('fullpath'));
  addpath(fullfile(aqui, 'funcoes'));
  if nargin < 1, opcoes = struct(); end
  P = preparar_propom(opcoes);
  codigo = '';
  inicio = now;
  R = cell(0, 3);
  R = reg_add(R, 'data', 'Data da coleta', datestr(inicio, 'yyyy-mm-dd'));
  R = reg_add(R, 'hora_inicio', 'Início do registro', datestr(inicio, 'HH:MM:SS'));
  desvios = {};

  printf('\n================ ProPOM — NOVA COLETA ================\n');
  printf('%s\n', datestr(inicio, 'dd/mm/yyyy HH:MM'));

  % ---------- 1. ambiente ----------
  printf('\n[1] Ambiente (UR %g–%g %% | temperatura %g–%g °C)\n', P.UR_faixa_pct, P.T_faixa_C);
  [A0, ok, desvio] = checar_faixa(P, 'inicio');
  if ~ok, printf('Coleta encerrada antes de iniciar (ambiente).\n'); return; end
  if ~isempty(desvio), desvios{end+1} = desvio; end
  R = reg_add(R, 'UR_checagem_pct', 'UR na checagem inicial (%)', A0.UR);
  R = reg_add(R, 'T_checagem_C', 'Temperatura do protótipo na checagem inicial (°C)', A0.T);
  R = reg_add(R, 'checagem_origem', 'Origem da checagem inicial', A0.origem);
  R = reg_add(R, 'checagem_hora', 'Hora da checagem inicial', A0.hora_leitura);

  % ---------- 2. checklist ----------
  printf('\n[2] Checklist do dia da coleta\n');
  chk = false(1, numel(P.checklist));
  for k = 1:numel(P.checklist)
    chk(k) = perguntar_sn(['  ' P.checklist{k}]);
    R = reg_add(R, sprintf('checklist_%d', k), P.checklist{k}, sn(chk(k)));
  end
  if ~all(chk)
    printf('  Itens NÃO atendidos: %s\n', strjoin(P.checklist(~chk), '; '));
    if ~perguntar_sn('  Prosseguir mesmo assim (desvio registrado)')
      printf('Coleta encerrada (checklist).\n'); return;
    end
    desvios{end+1} = 'checklist incompleto';
  end

  % ---------- 3. aclimatação ----------
  printf('\n[3] Aclimatação\n');
  while ~perguntar_sn('  Participante aclimatado')
    input('  Aguarde a aclimatação e pressione Enter para perguntar de novo.', 's');
  end
  R = reg_add(R, 'hora_aclimatado', 'Hora em que foi considerado aclimatado', datestr(now, 'HH:MM:SS'));

  % ---------- 4. participante ----------
  printf('\n[4] Participante\n');
  nome = perguntar_texto('  Nome completo', @(s) ~isempty(regexp(s, '[A-Za-zÀ-ú]', 'once')));
  nasc = perguntar_texto('  Data de nascimento (dd/mm/aaaa)', @data_valida, 'Use dd/mm/aaaa (data real).');
  sexo = upper(perguntar_texto('  Sexo: F = feminino | M = masculino', @(s) any(strcmpi(s, {'F','M'})), ...
                               'Digite apenas F ou M.'));
  codigo = codigo_participante(nome, nasc, sexo, inicio);
  printf('  Código da coleta: %s\n', codigo);
  pA = fullfile(P.pasta.ANAMNESE, codigo);
  if isfolder(pA), error('Já existe uma coleta com o código %s.', codigo); end
  mkdir(pA);
  mkdir(fullfile(P.pasta.TERMOCSV, codigo));
  mkdir(fullfile(P.pasta.TERMOJPG, codigo));
  anexar_csv(fullfile(P.pasta.ANAMNESE, 'identificacao_PRIVADO.csv'), ...
             {'codigo','nome','data_nascimento','sexo'}, {codigo, nome, nasc, sexo});
  R = reg_add(R, 'codigo', 'Código da coleta', codigo);
  R = reg_add(R, 'sexo', 'Sexo', sexo);
  R = reg_add(R, 'idade_anos', 'Idade (anos)', idade(nasc, inicio));
  arq_reg = fullfile(pA, 'registro.csv');
  salvar_registro(arq_reg, R);

  % ---------- 5. biometria ----------
  printf('\n[5] Dados biométricos\n');
  R = coletar_campos(R, P.biometria);
  peso = str2double(valor(R, 'peso_kg')); alt = str2double(valor(R, 'altura_cm'));
  imc = peso / (alt/100)^2;
  if isfinite(imc), printf('  IMC = %.1f kg/m²\n', imc); end
  R = reg_add(R, 'IMC_kgm2', 'IMC (kg/m²)', round(imc*10)/10);
  salvar_registro(arq_reg, R);

  % ---------- 6. sinais vitais ----------
  printf('\n[6] Sinais vitais\n');
  R = coletar_campos(R, P.sinais_vitais);
  R = reg_add(R, 'hora_sinais_vitais', 'Hora dos sinais vitais', datestr(now, 'HH:MM:SS'));
  salvar_registro(arq_reg, R);

  % ---------- 7. questionário ----------
  printf('\n[7] Questionário de autodeclaração de cognição\n');
  q_feito = perguntar_sn('  O questionário já foi respondido');
  R = reg_add(R, 'questionario_respondido', 'Questionário respondido', sn(q_feito));
  if q_feito && perguntar_sn('  Importar os dados do questionário agora')
    printf('  (CSVs em %s)\n', P.pasta.QUESTIONARIOS);
    Q = importar_questionario(P);
    if ~isempty(Q.arquivo)
      fq = fopen(fullfile(pA, 'questionario.csv'), 'w');
      fprintf(fq, 'campo,valor\n');
      for k = 1:numel(Q.cabecalho)
        fprintf(fq, '%s,%s\n', campo_csv(Q.cabecalho{k}), campo_csv(Q.valores{k}));
      end
      fclose(fq);
      [~, fn, fe] = fileparts(Q.arquivo);
      R = reg_add(R, 'questionario_arquivo', 'Arquivo do questionário', [fn fe]);
    end
  end
  R = reg_add(R, 'questionario_anotacao', 'Anotação do questionário', ...
              input('  Anotação/registro do questionário (Enter = nada): ', 's'));
  salvar_registro(arq_reg, R);

  % ---------- 8. orientação e posicionamento ----------
  printf('\n[8] Preparação\n');
  while ~perguntar_sn('  Participante orientado')
    input('  Oriente o participante e pressione Enter.', 's');
  end
  while ~perguntar_sn('  Posicionamento checado (apoio cefálico, visor, 50 cm)')
    input('  Ajuste o posicionamento e pressione Enter.', 's');
  end

  % ---------- 9. captura ----------
  printf('\n[9] Captura\n');
  capt = struct('condicao', {}, 'hora', {});
  t = timelapse(P.n_por_condicao, 'olhos abertos', P.intervalo_s);
  for k = 1:numel(t), capt(end+1) = struct('condicao', 'aberto', 'hora', t(k)); end %#ok<AGROW>
  printf('\n  Peça ao participante para FECHAR os olhos.\n');
  t = timelapse(P.n_por_condicao, 'olhos fechados', P.intervalo_s);
  for k = 1:numel(t), capt(end+1) = struct('condicao', 'fechado', 'hora', t(k)); end %#ok<AGROW>
  salvar_capturas(fullfile(pA, 'capturas.csv'), capt);
  while perguntar_sn(sprintf('\n  Deseja mais alguma tomada'))
    c = lower(perguntar_texto('  Condição: [a]berto ou [f]echado', @(s) any(strcmpi(s, {'a','f'}))));
    n = str2double(perguntar_texto('  Quantas imagens', @(s) any(str2double(s) == 1:20)));
    rot = 'aberto_extra'; if c == 'f', rot = 'fechado_extra'; end
    t = timelapse(n, strrep(rot, '_', ' '), P.intervalo_s);
    for k = 1:numel(t), capt(end+1) = struct('condicao', rot, 'hora', t(k)); end %#ok<AGROW>
    salvar_capturas(fullfile(pA, 'capturas.csv'), capt);
  end
  printf('\n  Coleta encerrada: %d imagens.\n', numel(capt));
  R = reg_add(R, 'hora_fim_captura', 'Fim da captura', datestr(now, 'HH:MM:SS'));
  R = reg_add(R, 'n_imagens', 'Número de imagens', numel(capt));

  R = reg_add(R, 'desvios', 'Desvios de protocolo', strjoin(desvios, '; '));
  R = reg_add(R, 'observacoes', 'Observações', ...
              input(sprintf('\nObservações gerais da coleta (Enter = nada): '), 's'));
  R = reg_add(R, 'status', 'Situação', 'registrada');
  salvar_registro(arq_reg, R);

  printf('\n================ COLETA %s REGISTRADA ================\n', codigo);
  printf('Agora coloque os arquivos da câmera em:\n');
  printf('   CSVs: %s\n', fullfile(P.pasta.TERMOCSV, codigo));
  printf('   JPGs: %s\n', fullfile(P.pasta.TERMOJPG, codigo));
  printf('e exporte o CSV do termo-higrômetro para:\n   %s\n', P.pasta.TEMUR);
  printf('Depois use "Processar coleta" no menu.\n');
end

function R = coletar_campos(R, campos)
  for i = 1:size(campos, 1)
    if isempty(campos{i,4})
      v = input(sprintf('  %s [Enter = não informado]: ', campos{i,2}), 's');
    else
      v = perguntar_numero(campos{i,2}, campos{i,3}, campos{i,4});
    end
    rot = campos{i,2};
    if ~isempty(campos{i,3}), rot = sprintf('%s (%s)', campos{i,2}, campos{i,3}); end
    R = reg_add(R, campos{i,1}, rot, v);
  end
end

function v = valor(R, k)
  i = find(strcmp(R(:,1), k), 1);
  v = ''; if ~isempty(i), v = R{i,3}; end
  if isnumeric(v), v = num2str(v); end
end

function a = idade(nasc, quando)
  d = sscanf(nasc, '%d/%d/%d');
  v = datevec(quando);
  a = v(1) - d(3) - ((v(2) < d(2)) || (v(2) == d(2) && v(3) < d(1)));
end

function salvar_capturas(arquivo, capt)
  fid = fopen(arquivo, 'w');
  fprintf(fid, 'ordem,condicao,data_hora\n');
  for k = 1:numel(capt)
    fprintf(fid, '%d,%s,%s\n', k, capt(k).condicao, datestr(capt(k).hora, 'yyyy-mm-dd HH:MM:SS'));
  end
  fclose(fid);
end
