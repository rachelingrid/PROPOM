% --- Início do Bloco de Análise Estatística ---

% --- Carrega Pacotes Necessários ---
pkg load io;
pkg load statistics;

disp("\n--- Iniciando Análise Estatística ---");

% --- Seleção de Arquivos via janela ---
arquivos = {};
caminhos = {};
cont = 1;
while true
  [f, p] = uigetfile("*.csv", sprintf("Selecione o arquivo CSV #%d para análise", cont));
  if isequal(f, 0)
    if cont <= 2
      errordlg("É necessário selecionar pelo menos 2 arquivos. Encerrando.", "Erro");
      return;
    endif
    break;
  endif
  arquivos{end+1} = f;
  caminhos{end+1} = p;
  if cont >= 2
    escolha = questdlg("Deseja selecionar mais um arquivo para análise?", "Mais Arquivos", "Sim", "Não", "Não");
    if ~strcmp(escolha, "Sim")
      break;
    endif
  endif
  cont++;
endwhile

% Se mais de dois arquivos, escolher quais usar na comparação
if numel(arquivos) > 2
  indices = listdlg("PromptString", "Selecione 2 arquivos para comparação", ...
                    "SelectionMode", "multiple", "ListString", arquivos, "Min", 2, "Max", 2);
  if numel(indices) ~= 2
    errordlg("Seleção inválida de arquivos. Precisam ser 2.", "Erro"); return;
  endif
  arquivo1 = arquivos{indices(1)}; caminho1 = caminhos{indices(1)};
  arquivo2 = arquivos{indices(2)}; caminho2 = caminhos{indices(2)};
else
  arquivo1 = arquivos{1}; caminho1 = caminhos{1};
  arquivo2 = arquivos{2}; caminho2 = caminhos{2};
endif

% --- Carrega Dados (pulando cabeçalho) ---
dados1_completo = dlmread(fullfile(caminho1, arquivo1), ',', 1, 0);
dados2_completo = dlmread(fullfile(caminho2, arquivo2), ',', 1, 0);

% --- Seleção de Colunas via diálogo ---
colunas = {"Temperatura Máxima","Temperatura Mínima","Temperatura Média","Temperatura Mediana", ...
            "Desvio Padrão","Variância","Amplitude (Máx–Mín)"};
idx1 = listdlg("PromptString","Selecione a coluna do 1º arquivo:", ...
               "SelectionMode","single","ListString",colunas);
if isempty(idx1)
    errordlg("Nenhuma coluna selecionada no 1º arquivo.","Erro"); return;
endif
dados1 = dados1_completo(:, idx1 + 4);

idx2 = listdlg("PromptString","Selecione a coluna do 2º arquivo:", ...
               "SelectionMode","single","ListString",colunas);
if isempty(idx2)
    errordlg("Nenhuma coluna selecionada no 2º arquivo.","Erro"); return;
endif
dados2 = dados2_completo(:, idx2 + 4);

% --- Menu de Análises via janela ---
tests = {"Teste t de Student (Welch)","Teste de Mann-Whitney U", ...
         "Teste de Wilcoxon Signed-Rank","Regressão Linear Simples", ...
         "ANOVA One-way","Teste Qui-Quadrado (2x2)","Teste de McNemar (2x2)"};
opc = listdlg("PromptString","Escolha o teste estatístico:", ...
               "SelectionMode","single","ListString",tests);
if isempty(opc)
    errordlg("Nenhum teste selecionado.","Erro"); return;
endif

% --- Executa o teste selecionado ---
resultado = '';
switch opc
  case 1  % Teste t de Student (Welch)
    [~,p,~,stats] = ttest2(dados1,dados2,'Vartype','unequal');
    resultado = sprintf("Teste t (Welch): t=%.4f, p=%.4f", stats.tstat, p);

  case 2  % Mann-Whitney U
    [p,~,stats] = ranksum(dados1,dados2);
    resultado = sprintf("Mann-Whitney U: U=%.4f, p=%.4f", stats.ranksum, p);

  case 3  % Wilcoxon Signed-Rank
    [p,~,stats] = signrank(dados1,dados2);
    resultado = sprintf("Wilcoxon Signed-Rank: W=%.4f, p=%.4f", stats.signedrank, p);

  case 4  % Regressão Linear Simples
    x = dados1(:); y = dados2(:);
    X = [ones(size(x)), x]; b = X \ y;
    yhat = X*b;
    R2 = 1 - sum((y-yhat).^2)/sum((y-mean(y)).^2);
    resultado = sprintf("Regressão Linear: intercepto=%.4f, coef.=%.4f, R²=%.4f", b(1), b(2), R2);

  case 5  % ANOVA One-way
    grupos = [ones(size(dados1));2*ones(size(dados2))];
    [p,tbl] = anova1([dados1;dados2], grupos, 'off');
    resultado = sprintf("ANOVA One-way: p=%.4f", p);

  case 6  % Qui-Quadrado 2x2
    resposta = inputdlg({'Insira tabela 2x2 [a b; c d]:'}, 'Qui-Quadrado', [1 50]);
    tbl2 = str2num(resposta{1});
    total = sum(tbl2(:)); rows = sum(tbl2,2); cols = sum(tbl2,1);
    exp = rows*cols/total;
    chi2 = sum((tbl2-exp).^2./exp,'all'); pval = 1-chi2cdf(chi2,1);
    resultado = sprintf("Qui-Quadrado: χ²=%.4f, p=%.4f", chi2, pval);

  case 7  % McNemar
    resp = inputdlg({'b (0→1)','c (1→0)'}, 'McNemar', [1 20]);
    b = str2double(resp{1}); c = str2double(resp{2});
    chi2 = (abs(b-c)-1)^2/(b+c); pval = 1-chi2cdf(chi2,1);
    resultado = sprintf("McNemar: χ²=%.4f, p=%.4f", chi2, pval);
end

% Exibe resultado do teste
msgbox(resultado, 'Resultado do Teste');

disp("\n--- Gerando Gráficos ---");
[~, base1] = fileparts(arquivo1);

% 1) Gráfico de Linhas
fig1 = figure;
hold on;
plot(1:length(dados1), dados1, '-o', 'LineWidth', 1.5);
plot(1:length(dados2), dados2, '-s', 'LineWidth', 1.5);
hold off;
legend('Grupo 1','Grupo 2','Location','northeast');
title('Gráfico de Linhas'); xlabel('Amostra'); ylabel('Valor');
print(fig1, sprintf('%s_line.png', base1), '-dpng');

% 2) Gráfico de Colunas (Bar)
fig2 = figure;
means = [mean(dados1), mean(dados2)];
bar(means);
set(gca, 'XTickLabel', {'G1','G2'});
title('Gráfico de Colunas - Médias'); ylabel('Média');
print(fig2, sprintf('%s_bar.png', base1), '-dpng');

% 3) Gráfico de Dispersão com cores distintas
n1 = numel(dados1);
n2 = numel(dados2);
fig3 = figure;
scatter(1:n1, dados1, 36, 'b', 'filled'); hold on;
scatter(1:n2, dados2, 36, 'r', 'filled'); hold off;
legend('Grupo 1','Grupo 2','Location','northeast');
title('Gráfico de Dispersão'); xlabel('Amostra'); ylabel('Valor');
print(fig3, sprintf('%s_scatter.png', base1), '-dpng');

% 4) Boxplot
fig4 = figure;
boxplot([dados1; dados2], [ones(size(dados1)); 2*ones(size(dados2))], 'Labels', {'G1','G2'});
title('Boxplot dos Grupos');
print(fig4, sprintf('%s_boxplot.png', base1), '-dpng');

% --- Geração de Relatório HTML ---
relatorio_html = sprintf('%s_report.html', base1);
fid_html = fopen(relatorio_html, 'w');
fprintf(fid_html, '<!DOCTYPE html>\n<html><head><meta charset="UTF-8"><title>Relatório %s</title></head><body>\n', base1);
fprintf(fid_html, '<h1>Relatório de Análise: %s</h1>\n', base1);
fprintf(fid_html, '<h2>Resultado do Teste Estatístico</h2><p>%s</p>\n', resultado);
fprintf(fid_html, '<h2>Gráficos</h2>\n');
fprintf(fid_html, '<h3>Linhas</h3><img src="%s_line.png" alt="Linhas"><br>\n', base1);
fprintf(fid_html, '<h3>Colunas</h3><img src="%s_bar.png" alt="Colunas"><br>\n', base1);
fprintf(fid_html, '<h3>Dispersão</h3><img src="%s_scatter.png" alt="Dispersão"><br>\n', base1);
fprintf(fid_html, '<h3>Boxplot</h3><img src="%s_boxplot.png" alt="Boxplot"><br>\n', base1);
fprintf(fid_html, '</body></html>');
fclose(fid_html);

msgbox(sprintf('Relatório HTML gerado: %s', relatorio_html), 'Concluído');

disp("\n--- Análise Estatística Concluída ---");

