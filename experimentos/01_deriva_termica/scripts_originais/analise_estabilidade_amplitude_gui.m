
clear; clc; close all;

%% ------------------------------------------------------------
% 1. Seleção dos arquivos CSV
% ------------------------------------------------------------
[files, path] = uigetfile("*.csv", ...
    "Selecione os arquivos CSV para análise", ...
    "MultiSelect", "on");

if isequal(files, 0)
    error("Nenhum arquivo selecionado.");
endif

if ischar(files)
    files = {files};
endif

%% ------------------------------------------------------------
% 2. Leitura robusta dos dados (via cabeçalho)
% ------------------------------------------------------------
A = [];

for i = 1:length(files)
    filepath = fullfile(path, files{i});

    fid = fopen(filepath, 'r');
    header = fgetl(fid);
    fclose(fid);

    % Detecta separador (Octave-safe)
    if ~isempty(strfind(header, ';'))
        sep = ';';
    else
        sep = ',';
    endif

    colnames = strsplit(header, sep);
    colnames = strtrim(colnames);

    idx_amp = find(strcmp(colnames, "Amplitude (°C)"));

    if isempty(idx_amp)
        warning("Arquivo %s ignorado (coluna Amplitude não encontrada).", files{i});
        continue;
    endif

    dados = dlmread(filepath, sep, 1, 0);

    amp = dados(:, idx_amp);
    amp = amp(~isnan(amp));

    A = [A; amp];
endfor

if isempty(A)
    error("Nenhum valor de amplitude foi carregado. Verifique o cabeçalho do CSV.");
endif
% Vetor temporal
N = length(A);
t = (1:N)';


%% ------------------------------------------------------------
% 3. Estatísticas descritivas
% ------------------------------------------------------------
A_mean   = mean(A);
A_median = median(A);
A_std    = std(A);
A_var    = var(A);
A_min    = min(A);
A_max    = max(A);

A_sorted = sort(A);
Q1 = A_sorted(round(0.25*N));
Q3 = A_sorted(round(0.75*N));
IQR = Q3 - Q1;

MAD = median(abs(A - A_median));

%% ------------------------------------------------------------
% 4. Gráficos
% ------------------------------------------------------------
figure;
plot(t, A, 'o-'); hold on;
plot(t, A_median * ones(size(t)), '--k');
xlabel("Índice temporal");
ylabel("Amplitude térmica (°C)");
title("Amplitude térmica ao longo do tempo");
grid on;

figure;
boxplot(A);
title("Distribuição da amplitude térmica");
ylabel("Amplitude (°C)");
grid on;

figure;
scatter(t, A - A_median, 'filled'); hold on;
plot(t, zeros(size(t)), '--k');
xlabel("Índice temporal");
ylabel("Desvio em relação à mediana (°C)");
title("Dispersão da amplitude");
grid on;

figure;
hist(A, 20); hold on;
yl = ylim;
plot([A_median A_median], yl, '--k');
xlabel("Amplitude térmica (°C)");
ylabel("Frequência");
title("Histograma da amplitude");
grid on;

