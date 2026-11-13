function P = config_propom()
% CONFIG_PROPOM  Parâmetros do ProPOM. Edite aqui; o resto do código não precisa mudar.

  % ================= PASTAS =================
  % Pasta-raiz dos dados. Pode trocar por um caminho fixo, ex.: 'C:\ProPOM'.
  % Dentro dela o programa cria e usa:
  %   TEMUR      CSVs exportados do termo-higrômetro (Govee)
  %   TERMOCSV   CSVs das imagens térmicas   (uma subpasta por coleta)
  %   TERMOJPG   JPGs capturados pela câmera  (uma subpasta por coleta)
  %   ANAMNESE   checklist, biometria, sinais vitais, questionário, identificação
  %              (+ ANAMNESE\QUESTIONARIOS: CSVs baixados do Mentaltracking)
  %   RESULTADOS processamento, relatórios e tabelas consolidadas
  P.raiz = fullfile(fileparts(mfilename('fullpath')), 'PROPOM_DADOS');

  % ================= LATERALIDADE =================
  % O participante fica DE FRENTE para a câmera: o olho DIREITO (OD) aparece
  % no lado ESQUERDO da imagem e o olho ESQUERDO (OE) no lado DIREITO.
  % Só troque para 'espelhada' se a câmera estiver com espelhamento ligado.
  P.espelhamento = 'nao_espelhada';

  % ================= AMBIENTE =================
  P.UR_faixa_pct = [40 60];        % umidade relativa aceitável
  P.T_faixa_C    = [23 25];        % temperatura do protótipo aceitável
  % Valor no momento de cada imagem, a partir dos CSVs da pasta TEMUR:
  %  'media_vizinhos' = média da leitura imediatamente anterior e da posterior
  %                     (10:00 = 40 %, 10:10 = 41 %, imagem às 10:06 -> 40,5 %)
  %  'linear'         = interpolação linear no tempo (mesmo exemplo -> 40,6 %)
  P.temur_metodo            = 'media_vizinhos';
  P.temur_intervalo_max_min = 15;  % leituras vizinhas mais afastadas que isso -> sem valor
  P.temur_idade_max_min     = 10;  % checagem inicial: só usa leitura do CSV com até 10 min

  % ================= CAPTURA =================
  P.intervalo_s    = 10;           % time-lapse entre imagens
  P.n_por_condicao = 5;            % 5 olhos abertos + 5 olhos fechados

  % ================= ANAMNESE =================
  P.checklist = { ...
    'Sem maquiagem, cremes ou protetor na face', ...
    'Sem exposição solar intensa no dia anterior', ...
    'Sem exercício físico intenso nas últimas 2 h', ...
    'Sem cafeína, álcool ou tabaco nas últimas 2 h', ...
    'Sem colírio nas últimas 2 h', ...
    'Sem febre ou sintomas agudos'};
  % {chave, rótulo, unidade, [mínimo máximo]}   ([] = campo de texto)
  % Enter em branco na coleta = não medido.
  P.biometria = { ...
    'peso_kg',   'Peso',   'kg', [20 300]; ...
    'altura_cm', 'Altura', 'cm', [100 230]};
  P.sinais_vitais = { ...
    'PAS_mmHg',       'Pressão arterial sistólica',   'mmHg', [60 260]; ...
    'PAD_mmHg',       'Pressão arterial diastólica',  'mmHg', [30 160]; ...
    'FC_bpm',         'Frequência cardíaca',          'bpm',  [30 220]; ...
    'FR_irpm',        'Frequência respiratória',      'irpm', [5 60]; ...
    'SpO2_pct',       'SpO2',                         '%',    [70 100]; ...
    'Tcorporal_C',    'Temperatura corporal',         '°C',   [34 42]; ...
    'Tcorporal_local','Local/método da temperatura',  '',     []};

  % ================= GEOMETRIA DA IMAGEM =================
  P.distancia_mm   = 500;          % distância foco-objeto fixa
  P.fov_h_graus    = 56;           % UNI-T UTi320E
  P.n_colunas      = 320;
  P.n_linhas       = 240;
  P.mm_por_px      = 2 * P.distancia_mm * tand(P.fov_h_graus/2) / P.n_colunas; % ~1,66 mm/px

  % ================= ROI =================
  P.faixa_valida_C        = [10 45]; % fora disso o arquivo vai para revisão
  P.margem_borda_mm       = 3.3;     % ~2 px: exclui pixels mistos da borda do visor
  P.endocanto_dist_min_mm = 5;       % distância horizontal mínima ao ápice nasal
  P.endocanto_dist_max_mm = 33;
  P.endocanto_acima_mm    = 23;
  P.endocanto_abaixo_mm   = 3;
  P.janela_suav_px        = 5;       % suavização SÓ para localizar pontos (nunca nas medidas)
  P.orbita_largura_mm     = 40;      % elipse orbital ancorada no endocanto
  P.orbita_altura_mm      = 35;
  P.orbita_medial_mm      = 5;
  P.limiar_palpebral      = [];      % vazio = classificação palpebral 'indeterminado'

  % ================= IMAGEM DE CONFERÊNCIA =================
  P.escala_png = 8;
  P.margem_png = 6;
end
