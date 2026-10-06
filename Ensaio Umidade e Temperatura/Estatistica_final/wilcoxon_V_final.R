1## ============================================================
## COMPARAÇÃO LAB x PRO - Cenário: Ar em modo Dry LIGADO
## Período: 16, 17 e 18 de maio
## Dados PAREADOS por horário | NÃO-NORMAIS -> teste de Wilcoxon
## ============================================================
## Objetivo: verificar se o PROTÓTIPO (PRO) mantém estabilidade de
## Temperatura e Umidade Relativa comparado ao Laboratório (LAB).
##
## Testes aplicados (por variável: TEMP e UR):
##   1) Wilcoxon signed-rank test (pareado)  -> diferença de nível/posição
##   2) Teste de Levene                       -> diferença de dispersão (estabilidade)
##   3) Desvio padrão e Coeficiente de Variação (CV%) -> estabilidade relativa
##   4) Tamanho de efeito r do Wilcoxon (r = Z / sqrt(n))
## ============================================================

## ---- 0. Pacotes -----------------------------------------------
pacotes <- c("readr", "dplyr", "ggplot2", "car")
novos <- pacotes[!(pacotes %in% installed.packages()[, "Package"])]
if (length(novos) > 0) install.packages(novos, repos = "https://cloud.r-project.org")

library(readr)
library(dplyr)
library(ggplot2)
library(car)   # leveneTest

## ---- 1. Configuração e Seleção de Arquivos ---------------------
## Seleção dos 2 arquivos via caixa de diálogo com proteção contra cancelamento.

if (.Platform$OS.type == "windows") {
  # No Windows, a caixa de diálogo mostra a instrução no título da janela
  arq_lab <- choose.files(caption = "1/2: Selecione o arquivo do LABORATÓRIO (LAB)", multi = FALSE)
  if (length(arq_lab) == 0) stop("Execução cancelada: Arquivo LAB não selecionado.")
  
  arq_pro <- choose.files(caption = "2/2: Selecione o arquivo do PROTÓTIPO (PRO)", multi = FALSE)
  if (length(arq_pro) == 0) stop("Execução cancelada: Arquivo PRO não selecionado.")
} else {
  # Mac/Linux: usa o file.choose() padrão
  cat("Atenção: Procure a janela de seleção e escolha o arquivo do LABORATÓRIO (LAB)...\n")
  arq_lab <- file.choose()
  
  cat("Atenção: Procure a janela de seleção e escolha o arquivo do PROTÓTIPO (PRO)...\n")
  arq_pro <- file.choose()
}

## Nome do cenário para gráficos e tabelas
if (.Platform$OS.type == "windows") {
  nome_cenario <- utils::winDialogString(
    "Digite um nome para este cenário (ex: Dry_LIGADO):",
    default = "Cenario_sem_nome"
  )
} else {
  nome_cenario <- paste0("Cenario_", format(Sys.time(), "%Y%m%d_%H%M%S"))
}

## Se o usuário cancelar a caixa de diálogo do nome, usa um nome padrão de data/hora
if (is.null(nome_cenario) || nome_cenario == "") {
  nome_cenario <- paste0("Cenario_", format(Sys.time(), "%Y%m%d_%H%M%S"))
}

## Pasta de saída: cria subpasta com o nome do cenário ao lado do arquivo LAB
pasta_saida <- file.path(dirname(arq_lab), paste0("saida_", nome_cenario))
dir.create(pasta_saida, showWarnings = FALSE)

## ---- 2. Leitura e padronização (Ajustado para ensaios em dias diferentes) ----
ler_arquivo <- function(caminho) {
  df <- read_csv(caminho, show_col_types = FALSE)
  names(df) <- trimws(names(df))
  # Encontra a coluna de data independentemente de como foi nomeada
  names(df)[grepl("DATA", names(df), ignore.case = TRUE)] <- "DATA_HORA"
  df$DATA_HORA <- as.POSIXct(df$DATA_HORA, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  return(df)
}

lab <- ler_arquivo(arq_lab)
pro <- ler_arquivo(arq_pro)

## Confere se a quantidade de linhas é igual, em vez de datas exatas
if (nrow(lab) != nrow(pro)) {
  stop("ERRO: Os arquivos têm tamanhos diferentes. Para comparar ensaios de dias diferentes, eles precisam ter a mesma duração (mesmo número de linhas).")
}

## Como os ensaios são de meses diferentes, copiamos a DATA do primeiro arquivo (LAB)
## para o segundo (PRO) apenas para garantir que fiquem sobrepostos no eixo X dos gráficos.
pro$DATA_HORA <- lab$DATA_HORA

cat("Alinhamento por tempo relativo OK. n =", nrow(lab), "observações comparadas minuto a minuto.\n\n")

## ---- 3. Função Wilcoxon e Levene para uma variável --------------
analisar_variavel <- function(x_lab, x_pro, v) {
  
  dif <- x_pro - x_lab   # positivo = PRO mais alto que LAB
  n <- length(dif)
  
  ## Wilcoxon signed-rank pareado
  wt <- wilcox.test(x_pro, x_lab, paired = TRUE, exact = FALSE, correct = TRUE)
  
  ## Tamanho de efeito r = Z / sqrt(n)
  z <- qnorm(wt$p.value / 2, lower.tail = FALSE) * sign(mean(dif))
  r_efeito <- z / sqrt(n)
  
  ## Teste de Levene (homogeneidade de variâncias)
  dados_levene <- data.frame(
    valor = c(x_lab, x_pro),
    grupo = factor(c(rep("LAB", n), rep("PRO", n)))
  )
  lev <- car::leveneTest(valor ~ grupo, data = dados_levene)
  
  desc <- tibble::tibble(
    cenario         = nome_cenario,
    variavel        = v,
    n               = n,
    media_LAB       = mean(x_lab, na.rm = TRUE),
    media_PRO       = mean(x_pro, na.rm = TRUE),
    diferenca_media = mean(dif, na.rm = TRUE),
    dp_LAB          = sd(x_lab, na.rm = TRUE),
    dp_PRO          = sd(x_pro, na.rm = TRUE),
    cv_LAB_pct      = 100 * (dp_LAB / media_LAB),
    cv_PRO_pct      = 100 * (dp_PRO / media_PRO),
    amplitude_LAB   = max(x_lab, na.rm = TRUE) - min(x_lab, na.rm = TRUE),
    amplitude_PRO   = max(x_pro, na.rm = TRUE) - min(x_pro, na.rm = TRUE),
    wilcoxon_V      = unname(wt$statistic),
    wilcoxon_p      = wt$p.value,
    efeito_r        = r_efeito,
    levene_p        = lev$`Pr(>F)`[1],
    mais_estavel    = ifelse(dp_PRO < dp_LAB, "PRO", "LAB")
  )
  
  list(desc = desc, dif = dif)
}

## ---- 4. Roda para TEMP e UR -------------------------------------
res_temp <- analisar_variavel(lab$TEMP, pro$TEMP, "TEMP")
res_ur   <- analisar_variavel(lab$UR,   pro$UR,   "UR")

resumo <- dplyr::bind_rows(res_temp$desc, res_ur$desc)
print(resumo, width = Inf)

# Salva a tabela final
write_csv(resumo, file.path(pasta_saida, paste0("resumo_wilcoxon_", nome_cenario, ".csv")))

## ---- 5. Gráficos --------------------------------------------------
for (v in c("TEMP", "UR")) {
  
  x_lab <- lab[[v]]
  x_pro <- pro[[v]]
  dif   <- x_pro - x_lab
  
  ## 5.1 Séries temporais sobrepostas
  df_plot <- data.frame(
    data  = rep(lab$DATA_HORA, 2),
    valor = c(x_lab, x_pro),
    grupo = rep(c("LAB", "PRO"), each = length(x_lab))
  )
  
  p_serie <- ggplot(df_plot, aes(x = data, y = valor, color = grupo)) +
    geom_line(linewidth = 0.4, alpha = 0.8) +
    labs(title = paste0(nome_cenario, " - ", v, ": LAB x PRO"),
         x = "Data/Hora", y = v, color = "Equipamento") +
    theme_minimal()
  ggsave(file.path(pasta_saida, paste0(nome_cenario, "_", v, "_serie.png")),
         p_serie, width = 9, height = 4, dpi = 150)
  
  ## 5.2 Boxplot comparativo
  df_box <- data.frame(valor = c(x_lab, x_pro),
                       grupo = rep(c("LAB", "PRO"), each = length(x_lab)))
  
  p_box <- ggplot(df_box, aes(x = grupo, y = valor, fill = grupo)) +
    geom_boxplot(alpha = 0.7) +
    labs(title = paste0(nome_cenario, " - ", v, ": Dispersão"), x = "", y = v) +
    theme_minimal() + 
    theme(legend.position = "none")
  ggsave(file.path(pasta_saida, paste0(nome_cenario, "_", v, "_boxplot.png")),
         p_box, width = 4, height = 4, dpi = 150)
  
  ## 5.3 Diferença PRO - LAB ao longo do tempo
  p_dif <- ggplot(data.frame(data = lab$DATA_HORA, dif = dif), aes(x = data, y = dif)) +
    geom_line(color = "darkorange", linewidth = 0.4) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
    labs(title = paste0(nome_cenario, " - ", v, ": Diferença (PRO - LAB)"),
         x = "Data/Hora", y = paste("Diferença", v)) +
    theme_minimal()
  ggsave(file.path(pasta_saida, paste0(nome_cenario, "_", v, "_diferenca.png")),
         p_dif, width = 9, height = 4, dpi = 150)
}

cat("\n==============================================\n")
cat("Concluído! Resultados gerados em:\n", normalizePath(pasta_saida), "\n")
cat("==============================================\n")
cat("\nGuia Rápido de Interpretação:\n")
cat("- wilcoxon_p <= 0.05 -> Diferença significativa na MEDIANA (Nível) entre LAB e PRO.\n")
cat("- levene_p   <= 0.05 -> Diferença significativa na VARIÂNCIA (Estabilidade).\n")
cat("- cv_PRO_pct vs cv_LAB_pct -> O menor CV% indica quem é mais estável.\n")
cat("- efeito_r -> Força da diferença: ~0.1 (Pequeno) | ~0.3 (Médio) | >0.5 (Grande).\n")
