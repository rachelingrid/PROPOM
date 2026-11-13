function propom_roi(pasta_imagens, pasta_saida, arquivo_protocolo)
% PROPOM_ROI  Seleção da ROI 3x3 periorbital medial (OD e OE).
%
% Uso:  propom_roi(pasta_imagens, pasta_saida)
%       propom_roi(pasta_imagens, pasta_saida, arquivo_protocolo)
%
% arquivo_protocolo (padrão: pasta_imagens/protocolo.csv):
%   participante,sessao,ordem,arquivo,condicao_protocolo[,hora_captura]
% pontos_manuais.csv opcional na pasta de imagens:
%   arquivo,N_lin,N_col,OD_lin,OD_col,OE_lin,OE_col
%
% Saídas em pasta_saida: integridade.csv, resultados_individuais.csv,
% resumo_por_condicao.csv, conferencia/*.png, mascaras/*.mat
%
% Lateralidade: sempre a do PARTICIPANTE (OD = olho direito, OE = olho
% esquerdo). Participante de frente -> OD aparece à esquerda da imagem.

  aqui = fileparts(mfilename('fullpath'));
  addpath(fullfile(aqui, 'funcoes'));
  P = config_propom();
  if nargin < 3 || isempty(arquivo_protocolo)
    arquivo_protocolo = fullfile(pasta_imagens, 'protocolo.csv');
  end

  [~, ~] = mkdir(pasta_saida);
  [~, ~] = mkdir(fullfile(pasta_saida, 'conferencia'));
  [~, ~] = mkdir(fullfile(pasta_saida, 'mascaras'));

  % ---------- 1. protocolo ----------
  [cab, prot] = ler_csv_texto(arquivo_protocolo);
  ix = @(nome) find(strcmp(cab, nome));
  tem_hora = ~isempty(ix('hora_captura'));
  manual = ler_manuais(fullfile(pasta_imagens, 'pontos_manuais.csv'));

  fi = fopen(fullfile(pasta_saida, 'integridade.csv'), 'w');
  fprintf(fi, 'arquivo,ok,motivo,linhas_lidas,colunas_lidas,coluna_vazia_removida,n_ausentes,n_fora_faixa,Tmin,Tmax\n');

  fr = fopen(fullfile(pasta_saida, 'resultados_individuais.csv'), 'w');
  fprintf(fr, ['participante,sessao,ordem,arquivo,condicao_protocolo,hora_captura,olho,lado_na_imagem,' ...
               'estado_palpebral_auto,indice_palpebral,theta_graus,N_lin,N_col,endocanto_lin,endocanto_col,origem_pontos,' ...
               'frac_orbita_no_visor,n_pixels_elegiveis,n_janelas_avaliadas,n_empates,linha_centro,coluna_centro,' ...
               'v11,v21,v31,v12,v22,v32,v13,v23,v33,' ...
               'maximo,minimo,media,mediana,desvio_padrao,variancia,amplitude,observacao\n']);

  medidas = {'maximo','minimo','media','mediana','desvio_padrao','variancia','amplitude'};
  todos = struct([]);

  for k = 1:size(prot, 1)
    reg.participante = prot{k, ix('participante')};
    reg.sessao       = prot{k, ix('sessao')};
    reg.ordem        = prot{k, ix('ordem')};
    reg.arquivo      = prot{k, ix('arquivo')};
    reg.condicao     = prot{k, ix('condicao_protocolo')};
    reg.hora = ''; if tem_hora, reg.hora = prot{k, ix('hora_captura')}; end
    [~, base] = fileparts(reg.arquivo);

    % ---------- 2. leitura e integridade ----------
    [T, integ] = ler_matriz_termica(fullfile(pasta_imagens, reg.arquivo), P);
    fprintf(fi, '%s,%d,%s,%d,%d,%d,%d,%d,%.2f,%.2f\n', reg.arquivo, integ.ok, integ.motivo, ...
            integ.linhas_lidas, integ.colunas_lidas, integ.coluna_vazia_removida, ...
            integ.n_ausentes, integ.n_fora_faixa, integ.Tmin, integ.Tmax);
    if ~integ.ok
      printf('[REVISAR] %s: %s\n', reg.arquivo, integ.motivo);
      continue;
    end
    T_original = T;

    % ---------- 3. visor, pontos anatômicos ----------
    [visor, visor_util, limiar] = mascara_visor(T, P);
    man = struct();
    chave = matlab.lang.makeValidName(base);
    if isfield(manual, chave), man = manual.(chave); end
    L = localizar_pontos(T, visor, visor_util, P, man);
    if ~L.ok
      printf('[REVISAR] %s: %s\n', reg.arquivo, L.motivo);
      continue;
    end
    % ---------- 5-6. órbitas, quadrantes e pele elegível ----------
    R = regioes_orbitais(L, visor_util, T, P);

    J = struct();
    for olho = {'OD', 'OE'}
      id = olho{1};
      % ---------- 4. pálpebra (exploratório) ----------
      Cp = classificar_palpebra(T, R, id, visor_util, P);
      % ---------- 7-9. janela 3x3 e medidas ----------
      Js = selecionar_janela_3x3(T, R.(id).elegivel);
      J.(id) = Js;

      obs = '';
      if ~Js.ok, obs = 'sem janela 3x3 inteiramente elegivel'; end
      if Js.n_empates > 0, obs = sprintf('%d empate(s) na media maxima', Js.n_empates); end
      lado_img = 'esquerdo'; if sinal_lado(id, P) > 0, lado_img = 'direito'; end
      origem = sprintf('N:%s|%s:%s', L.origem_N, id, L.(['origem_' id]));
      canto = L.(id);
      fprintf(fr, '%s,%s,%s,%s,%s,%s,%s,%s,%s,%.4f,%.2f,%d,%d,%d,%d,%s,%.3f,%d,%d,%d,%d,%d,', ...
        reg.participante, reg.sessao, reg.ordem, reg.arquivo, reg.condicao, reg.hora, id, lado_img, ...
        Cp.classe, Cp.indice, R.theta_graus, L.N(1), L.N(2), canto(1), canto(2), ...
        origem, R.(id).frac_orbita_no_visor, sum(R.(id).elegivel(:)), Js.n_janelas, Js.n_empates, ...
        Js.linha_centro, Js.coluna_centro);
      fprintf(fr, '%.2f,', Js.valores(:));
      fprintf(fr, '%.4f,%.4f,%.4f,%.4f,%.4f,%.6f,%.4f,%s\n', Js.maximo, Js.minimo, Js.media, ...
              Js.mediana, Js.desvio_padrao, Js.variancia, Js.amplitude, obs);

      linha = struct('participante', reg.participante, 'sessao', reg.sessao, ...
                     'condicao', reg.condicao, 'olho', id);
      for q = 1:numel(medidas), linha.(medidas{q}) = Js.(medidas{q}); end
      if isempty(todos), todos = linha; else, todos(end+1) = linha; end %#ok<AGROW>
    end

    % garantia: a matriz analisada é idêntica à lida
    assert(isequaln(T, T_original), 'matriz original foi alterada');

    % ---------- 10. máscaras e conferência ----------
    mascaras = struct();
    mascaras.arquivo = reg.arquivo; mascaras.limiar_visor_C = limiar;
    mascaras.visor = visor; mascaras.visor_util = visor_util; mascaras.pontos = L;
    mascaras.theta_graus = R.theta_graus; mascaras.espelhamento = P.espelhamento;
    for id = {'OD', 'OE'}
      mascaras.(['orbita_' id{1}])     = R.(id{1}).orbita;
      mascaras.(['quadrantes_' id{1}]) = uint8(R.(id{1}).quadrantes);
      mascaras.(['elegivel_' id{1}])   = R.(id{1}).elegivel;
      mascaras.(['janela_' id{1}])     = [J.(id{1}).linha_centro J.(id{1}).coluna_centro];
    end
    save('-mat7-binary', fullfile(pasta_saida, 'mascaras', [base '.mat']), '-struct', 'mascaras');
    imagem_conferencia(fullfile(pasta_saida, 'conferencia', [base '.png']), ...
                       T, visor, visor_util, L, R, J, P);
    printf('%s  OD:(%d,%d) %.2f °C   OE:(%d,%d) %.2f °C\n', reg.arquivo, ...
           J.OD.linha_centro, J.OD.coluna_centro, J.OD.media, J.OE.linha_centro, J.OE.coluna_centro, J.OE.media);
  end
  fclose(fi); fclose(fr);

  % ---------- 11. resumo por condição (depois dos individuais) ----------
  fs = fopen(fullfile(pasta_saida, 'resumo_por_condicao.csv'), 'w');
  fprintf(fs, 'participante,sessao,condicao_protocolo,olho,medida,n_imagens,media,desvio_padrao,mediana,minimo,maximo\n');
  if ~isempty(todos)
    rot = @(t) sprintf('%s|%s|%s|%s', t.participante, t.sessao, t.condicao, t.olho);
    chaves = unique(arrayfun(rot, todos, 'UniformOutput', false));
    for c = 1:numel(chaves)
      p = strsplit(chaves{c}, '|');
      sel = arrayfun(@(t) strcmp(rot(t), chaves{c}), todos);
      for q = 1:numel(medidas)
        x = [todos(sel).(medidas{q})]; x = x(isfinite(x));
        fprintf(fs, '%s,%s,%s,%s,%s,%d,%.4f,%.4f,%.4f,%.4f,%.4f\n', p{1}, p{2}, p{3}, p{4}, ...
                medidas{q}, numel(x), mean(x), std(x), median(x), min(x), max(x));
      end
    end
  end
  fclose(fs);
  printf('Processamento térmico concluído: %s\n', pasta_saida);
end

function M = ler_manuais(arquivo)
  M = struct();
  if ~exist(arquivo, 'file'), return; end
  [cab, lin] = ler_csv_texto(arquivo);
  for i = 1:size(lin, 1)
    [~, base] = fileparts(lin{i, strcmp(cab, 'arquivo')});
    nomes = {'N','OD','OE'}; m = struct();
    for n = 1:3
      a = str2double(lin{i, strcmp(cab, [nomes{n} '_lin'])});
      b = str2double(lin{i, strcmp(cab, [nomes{n} '_col'])});
      m.(nomes{n}) = [a b];
    end
    M.(matlab.lang.makeValidName(base)) = m;
  end
end
