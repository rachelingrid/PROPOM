% Início do Script de Análise de Imagens Térmicas
clear
clc
% --- Carrega Pacotes Necessários ---
pkg load io;
pkg load statistics;

% --- Loop Principal de Análise em Lote ---
continuar_analise = true;
contador_analise  = 1;

while (continuar_analise)
    % --- Bloco de Configuração Inicial por Lote ---
    if exist('inputdlg','file')
        prompt = {
            'Data da coleta (DD/MM/AAAA):', ...
            'Umidade relativa do ar (%):', ...
            'Temperatura do ar (°C):'
        };
        dlg_title   = 'Configuração por Lote';
        num_lines   = [1 30; 1 30; 1 30];
        defaultans  = {datestr(now,'dd/mm/yyyy'), '', ''};
        answer      = inputdlg(prompt, dlg_title, num_lines, defaultans);
        if isempty(answer)
            error('Configuração não fornecida. Abortando.');
        endif
        data_coleta      = answer{1};
        umidade_relativa = str2double(answer{2});
        temperatura_ar   = str2double(answer{3});
    else
        disp('--- Configuração por Lote ---');
        data_coleta      = input('Data da coleta (DD/MM/AAAA): ', 's');
        umidade_relativa = input('Umidade relativa do ar (%): ');
        temperatura_ar   = input('Temperatura do ar (°C): ');
    endif

    % Seleciona a pasta contendo os CSV de matrizes térmicas
    pasta_matrizes = uigetdir(pwd, 'Selecione a pasta com os CSVs de matrizes térmicas');
    if isequal(pasta_matrizes, 0)
        disp('Nenhuma pasta selecionada. Encerrando a análise.');
        break;
    endif

    % Lista todos os arquivos CSV na pasta
    arquivos_info = dir(fullfile(pasta_matrizes, '*.csv'));
    if isempty(arquivos_info)
        disp('Nenhum CSV de matriz térmica encontrado na pasta selecionada.');
    else
        % Cria o arquivo CSV de saída para este lote de análise
        nome_saida = sprintf('analise_lote_%d.csv', contador_analise);
        fid = fopen(nome_saida, 'w');

        % --- Cabeçalho do CSV de saída (com as colunas adicionais) ---
        fprintf(fid, [
          'Nome do Arquivo,Data Coleta,UR Coleta (%%),Temp Coleta (°C),' ...
          'Temp Máx (°C),Temp Mín (°C),Temp Méd (°C),Temp Mediana (°C),' ...
          'Desvio Padrão (°C),Variância (°C^2),Amplitude (°C)\n'
        ]);

        % Processa cada matriz térmica
        for i = 1:length(arquivos_info)
            try
                nome_base = arquivos_info(i).name;
                caminho   = fullfile(pasta_matrizes, nome_base);

                % Lê a matriz de temperaturas (°C)
                matriz    = dlmread(caminho, ',');

                % Estatísticas existentes
                tmax      = max(matriz(:));
                tmin      = min(matriz(:));
                tmed      = mean(matriz(:));
                tmediana  = median(matriz(:));

                % NOVAS ESTATÍSTICAS
                sd        = std(matriz(:));   % desvio‑padrão
                varianca  = var(matriz(:));   % variância
                amplitude = tmax - tmin;      % amplitude

                % Escreve linha no CSV de saída
                fprintf(fid, '%s,%s,%.1f,%.1f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n', ...
                    nome_base, data_coleta, umidade_relativa, temperatura_ar, ...
                    tmax, tmin, tmed, tmediana, sd, varianca, amplitude
                );

                fprintf('"%s" analisado. Máx=%.2f, Mín=%.2f, SD=%.2f\n', ...
                    nome_base, tmax, tmin, sd);
            catch ME
                fprintf('Erro ao processar "%s": %s\n', nome_base, ME.message);
            end_try_catch
        endfor

        fclose(fid);
        fprintf('\nLote #%d concluído. Dados salvos em "%s".\n', contador_analise, nome_saida);
    endif

    % --- Pergunta se deseja novo lote ou executar análise estatística ---
    resp = input('Deseja iniciar um novo lote de análise? (s/n): ', 's');
    if lower(resp) == 's'
        contador_analise = contador_analise + 1;
    else
        % Finaliza os lotes e chama análise estatística
        disp('\n--- Todas as análises em lote concluídas ---');
        try
            AE; % Executa o script AE.m para análise estatística
        catch ME
            warning('Falha ao executar AE.m: %s', ME.message);
        end_try_catch
        break;
    endif
endwhile

