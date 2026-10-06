## ============================================================
## TESTE DE NORMALIDADE - Dados de Temperatura e Umidade Relativa
## ============================================================
## Este script:
##   1. Le os arquivos CSV (PRO = ambiente externo/protótipo, LAB = laboratório)
##   2. Para cada arquivo e cada variável (TEMP, UR), aplica:
##        - Teste de Shapiro-Wilk   (recomendado para n <= 5000)
##        - Teste de Kolmogorov-Smirnov (Lilliefors, mais robusto p/ n grande)
##        - Assimetria (skewness) e curtose (kurtosis)
##   3. Gera QQ-plots e histogramas com curva normal sobreposta
##   4. Salva uma tabela resumo (.csv) e os gráficos (.png)
## ============================================================

## ---- 0. Checar, Instalar e Carregar Pacotes --------------------------------

# Lista de pacotes necessários
pacotes <- c("nortest", "moments", "ggplot2", "dplyr", "purrr", "readr", "tidyr")

# 1. Checa quais pacotes NÃO estão instalados
pacotes_faltantes <- pacotes[!(pacotes %in% installed.packages()[,"Package"])]

# 2. Instala automaticamente apenas os que faltam
if(length(pacotes_faltantes) > 0) {
  message("Instalando pacotes faltantes: ", paste(pacotes_faltantes, collapse = ", "))
  install.packages(pacotes_faltantes, dependencies = TRUE, repos = "https://cloud.r-project.org")
}

## ---- 1. Configuração ----------------------------------------

# Abre a caixa de diálogo do Windows para seleção múltipla de arquivos
arquivos <- choose.files(
  caption = "Selecione os arquivos CSV para avaliação",
  filters = matrix(c("Arquivos CSV", "*.csv"), 1, 2),
  multi = TRUE
)

# Trava de segurança: interrompe o script se você fechar a janela sem selecionar nada
if (length(arquivos) == 0) {
  stop("Nenhum arquivo foi selecionado. Execute o bloco novamente.")
}

# Extrai o caminho da pasta do primeiro arquivo selecionado para criar a pasta de saída no mesmo local
pasta_origem <- dirname(arquivos[1])
pasta_saida  <- file.path(pasta_origem, "saida_normalidade")
dir.create(pasta_saida, showWarnings = FALSE)

## Variáveis numéricas que serão testadas
variaveis <- c("TEMP", "UR")

## ---- 2. Função para ler 1 arquivo, padronizando nomes -------
ler_arquivo <- function(caminho) {
  df <- read_csv(caminho, show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  # Padroniza nome da coluna de data/hora (alguns arquivos têm espaço: "DATA _HORA")
  names(df) <- trimws(names(df))
  names(df)[grepl("DATA", names(df), ignore.case = TRUE)] <- "DATA_HORA"
  df$DATA_HORA <- as.POSIXct(df$DATA_HORA, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  df$arquivo <- basename(caminho)
  df
}

## ---- 3. Lê todos os arquivos em uma lista nomeada ------------
dados_lista <- map(arquivos, ler_arquivo)
names(dados_lista) <- basename(arquivos)

## ---- 4. Função que aplica os testes de normalidade -----------
testar_normalidade <- function(x, nome_var, nome_grupo) {
  x <- x[!is.na(x)]
  n <- length(x)

  # Shapiro-Wilk exige 3 <= n <= 5000. Se a amostra for maior, tira uma
  # amostra aleatória de 5000 pontos só para esse teste (prática comum),
  # mas o KS/Lilliefors abaixo usa a amostra completa.
  if (n >= 3) {
    if (n <= 5000) {
      sw <- shapiro.test(x)
    } else {
      set.seed(123)
      sw <- shapiro.test(sample(x, 5000))
    }
  } else {
    sw <- list(statistic = NA, p.value = NA)
  }

  # Lilliefors (KS adaptado para quando média/DP são estimados dos dados)
  lf <- tryCatch(lillie.test(x), error = function(e) list(statistic = NA, p.value = NA))

  tibble(
    arquivo       = nome_grupo,
    variavel      = nome_var,
    n             = n,
    media         = mean(x),
    desvio_padrao = sd(x),
    assimetria    = moments::skewness(x),
    curtose       = moments::kurtosis(x) - 3,  # curtose em excesso (normal = 0)
    shapiro_W     = unname(sw$statistic),
    shapiro_p     = sw$p.value,
    lilliefors_D  = unname(lf$statistic),
    lilliefors_p  = lf$p.value,
    normal_5pct   = ifelse(!is.na(lf$p.value) & lf$p.value > 0.05 &
                            !is.na(sw$p.value) & sw$p.value > 0.05,
                            "Sim", "Não")
  )
}

## ---- 5. Roda os testes para cada arquivo x variável -----------
resultados <- map_dfr(names(dados_lista), function(nome_arq) {
  df <- dados_lista[[nome_arq]]
  map_dfr(variaveis, function(v) {
    testar_normalidade(df[[v]], v, nome_arq)
  })
})

print(resultados, n = Inf, width = Inf)

## Salva tabela resumo
write_csv(resultados, file.path(pasta_saida, "resumo_testes_normalidade.csv"))

## ---- 6. Gráficos diagnósticos (histograma + QQ-plot) -----------
for (nome_arq in names(dados_lista)) {
  df <- dados_lista[[nome_arq]]
  for (v in variaveis) {

    x <- df[[v]]
    x <- x[!is.na(x)]

    # Histograma com curva normal teórica sobreposta
    p_hist <- ggplot(data.frame(x = x), aes(x = x)) +
      geom_histogram(aes(y = after_stat(density)), bins = 40,
                      fill = "steelblue", alpha = 0.6, color = "white") +
      stat_function(fun = dnorm,
                     args = list(mean = mean(x), sd = sd(x)),
                     color = "darkred", linewidth = 1) +
      labs(title = paste("Histograma -", v, "-", nome_arq),
           x = v, y = "Densidade") +
      theme_minimal()

    # QQ-plot
    p_qq <- ggplot(data.frame(x = x), aes(sample = x)) +
      stat_qq(color = "steelblue", alpha = 0.5) +
      stat_qq_line(color = "darkred", linewidth = 1) +
      labs(title = paste("QQ-plot -", v, "-", nome_arq),
           x = "Quantis teóricos", y = "Quantis amostrais") +
      theme_minimal()

    nome_base <- tools::file_path_sans_ext(nome_arq)
    ggsave(file.path(pasta_saida, paste0(nome_base, "_", v, "_hist.png")),
           p_hist, width = 6, height = 4, dpi = 150)
    ggsave(file.path(pasta_saida, paste0(nome_base, "_", v, "_qqplot.png")),
           p_qq, width = 6, height = 4, dpi = 150)
  }
}

cat("\n==============================================\n")
cat("Concluído! Resultados salvos em:", normalizePath(pasta_saida), "\n")
cat("==============================================\n")
cat("\nComo interpretar:\n")
cat("- p-valor > 0.05  -> não rejeita H0 -> dados compatíveis com distribuição normal\n")
cat("- p-valor <= 0.05 -> rejeita H0 -> dados NÃO seguem distribuição normal\n")
cat("- Com n grande (milhares de pontos, como aqui), pequenos desvios da\n")
cat("  normalidade tornam os testes 'significativos' com facilidade.\n")
cat("  Por isso, SEMPRE olhe também o histograma e o QQ-plot, e não só o p-valor.\n")
