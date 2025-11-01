# Cargar las librerías necesarias

install.packages("languageserver")

remotes::install_github("nx10/httpgd")

remotes::install_github("ManuelHentschel/vscDebugger")

# Crear .Rprofile en el directorio HOME
file.edit(file.path(Sys.getenv("HOME"), ".Rprofile"))

# O crear en el directorio actual del proyecto
file.edit(".Rprofile")

install.packages("pandoc")

library(shiny)
library(ggplot2)
library(tidyverse)

df_mat <- read_csv2("student-mat.csv")
df_por <- read_csv2("student-por.csv")

View(df_mat)
View(df_por)

# Realizar un EDA para cada df
# Análisis descriptivo
summary(df_mat)
summary(df_por)

# --- Análisis exploratorio completo (funciones reutilizables) ---

# Funciones auxiliares
numeric_stats <- function(df) {
  df |>
    select(where(is.numeric)) |>
    summarise_all(list(
      n = ~sum(!is.na(.)),
      missing = ~sum(is.na(.)),
      mean = ~mean(., na.rm = TRUE),
      sd = ~sd(., na.rm = TRUE),
      median = ~median(., na.rm = TRUE),
      min = ~min(., na.rm = TRUE),
      max = ~max(., na.rm = TRUE)
    )) |>
    pivot_longer(everything(),
                 names_to = c("variable", ".value"),
                 names_sep = "_", values_drop_na = FALSE)
}

missing_table <- function(df) {
  tibble(
    variable = names(df),
    missing = sapply(df, function(x) sum(is.na(x))),
    missing_pct = round(missing / nrow(df) * 100, 2)
  ) |> arrange(desc(missing))
}

detect_outliers_iqr <- function(x) {
  if (!is.numeric(x)) return(integer(0))
  Q1 <- quantile(x, 0.25, na.rm = TRUE)
  Q3 <- quantile(x, 0.75, na.rm = TRUE)
  IQR <- Q3 - Q1
  lower <- Q1 - 1.5 * IQR
  upper <- Q3 + 1.5 * IQR
  which(x < lower | x > upper)
}

outliers_table <- function(df) {
  nums <- df %>% select(where(is.numeric))
  map_dfr(names(nums), function(v) {
    idx <- detect_outliers_iqr(nums[[v]])
    tibble(
      variable = v,
      outlier_count = length(idx),
      example_indices = if (length(idx) == 0) NA_character_ else paste(head(idx, 10), collapse = ","),
      example_values = if (length(idx) == 0) NA_character_ else paste(round(head(nums[[v]][idx], 10), 4), collapse = ",")
    )
  }) %>% arrange(desc(outlier_count))
}

# Correlación entre variables numéricas
correlation_analysis <- function(df, threshold = 0.7) {
  nums <- df %>% select(where(is.numeric))
  if (ncol(nums) < 2) return(tibble())
  cor_mat <- cor(nums, use = "pairwise.complete.obs")
  # detectar pares con correlación fuerte (excluye 1.0 en diagonal)
  strong_pairs <- which(abs(cor_mat) >= threshold & abs(cor_mat) < 1, arr.ind = TRUE)
  if (nrow(strong_pairs) == 0) {
    strong_df <- tibble()
  } else {
    strong_df <- tibble(
      var1 = rownames(cor_mat)[strong_pairs[,1]],
      var2 = colnames(cor_mat)[strong_pairs[,2]],
      correlation = cor_mat[strong_pairs]
    ) %>% distinct() %>% arrange(desc(abs(correlation)))
  }
  list(cor_mat = cor_mat, strong = strong_df)
}

# Gráficos resumen (guardados en el disco)
plot_eda <- function(df, prefix) {
  dir.create("EDA_plots", showWarnings = FALSE)
  # Histograma G3
  if ("G3" %in% names(df)) {
    p1 <- ggplot(df, aes(x = G3)) +
      geom_histogram(binwidth = 1, fill = "#2c7fb8", color = "white") +
      labs(title = paste(prefix, "- Distribución de G3"), x = "G3", y = "Frecuencia") +
      theme_minimal()
    ggsave(filename = paste0("EDA_plots/", prefix, "_hist_G3.png"), plot = p1, width = 7, height = 4)
  }
  # Boxplots por variable numérica (panel)
  nums <- df %>% select(where(is.numeric))
  if (ncol(nums) > 0) {
    nums_long <- nums %>% pivot_longer(everything(), names_to = "variable", values_to = "value")
    p2 <- ggplot(nums_long, aes(x = variable, y = value)) +
      geom_boxplot(outlier.size = 1, fill = "#74a9cf") +
      coord_flip() +
      labs(title = paste(prefix, "- Boxplots variables numéricas")) +
      theme_minimal()
    ggsave(filename = paste0("EDA_plots/", prefix, "_boxplots_num.png"), plot = p2, width = 9, height = max(4, ncol(nums) * 0.2 + 4))
  }
  # Mapa de correlación (si hay >=2 num variables)
  if (ncol(nums) >= 2) {
    cor_mat <- cor(nums, use = "pairwise.complete.obs")
    cor_df <- as.data.frame(as.table(cor_mat))
    p3 <- ggplot(cor_df, aes(Var1, Var2, fill = Freq)) +
      geom_tile() +
      scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0) +
      labs(title = paste(prefix, "- Mapa de correlación (num)")) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      coord_fixed()
    ggsave(filename = paste0("EDA_plots/", prefix, "_correlation_map.png"), plot = p3, width = 7, height = 6)
  }
  # Scatter G3 vs top correlates
  if ("G3" %in% names(nums) && ncol(nums) >= 2) {
    cor_with_G3 <- cor(nums, use = "pairwise.complete.obs")[, "G3", drop = FALSE]
    cor_with_G3 <- tibble(variable = rownames(cor_with_G3), corr = cor_with_G3[,1]) %>%
      filter(variable != "G3") %>%
      arrange(desc(abs(corr)))
    top_vars <- head(cor_with_G3$variable, 6)
    if (length(top_vars) > 0) {
      scatter_df <- df %>% select(all_of(c("G3", top_vars))) %>% pivot_longer(-G3, names_to = "variable", values_to = "value")
      p4 <- ggplot(scatter_df, aes(x = value, y = G3)) +
        geom_point(alpha = 0.6, size = 1.5, color = "#2b8cbe") +
        geom_smooth(method = "lm", se = FALSE, color = "red") +
        facet_wrap(~variable, scales = "free_x") +
        labs(title = paste(prefix, "- G3 vs variables con mayor correlación")) +
        theme_minimal()
      ggsave(filename = paste0("EDA_plots/", prefix, "_G3_top_scatter.png"), plot = p4, width = 10, height = 6)
    }
  }
}

# Ejecutar EDA para un df y retornar resultados en lista
run_full_eda <- function(df, name) {
  cat("=== EDA para:", name, "===\n")
  res <- list()
  res$dim <- dim(df)
  res$glimpse <- glimpse(df)
  res$numeric_summary <- numeric_stats(df)
  res$missing <- missing_table(df)
  res$outliers <- outliers_table(df)
  res$correlation <- correlation_analysis(df, threshold = 0.7)
  plot_eda(df, name)
  # Guardar tablas como csv
  write_csv(res$numeric_summary, paste0("EDA_plots/", name, "_numeric_summary.csv"))
  write_csv(res$missing, paste0("EDA_plots/", name, "_missing.csv"))
  write_csv(res$outliers, paste0("EDA_plots/", name, "_outliers.csv"))
  if (nrow(res$correlation$strong) > 0) {
    write_csv(res$correlation$strong, paste0("EDA_plots/", name, "_strong_correlations.csv"))
  } else {
    write_csv(tibble(), paste0("EDA_plots/", name, "_strong_correlations.csv"))
  }
  invisible(res)
}

# Ejecutar para df_mat y df_por
eda_mat <- run_full_eda(df_mat, "student_mat")
eda_por <- run_full_eda(df_por, "student_por")

# Impresión resumida de hallazgos clave
cat("student_mat: dimensiones =", eda_mat$dim, "\n")
cat("student_por: dimensiones =", eda_por$dim, "\n")

# Mostrar tablas importantes en consola
print("Missing values - student_mat:")
print(eda_mat$missing)
print("Outliers (IQR rule) - student_mat:")
print(eda_mat$outliers %>% filter(outlier_count > 0))

print("Missing values - student_por:")
print(eda_por$missing)
print("Outliers (IQR rule) - student_por:")
print(eda_por$outliers %>% filter(outlier_count > 0))

# Lista de variables con fuerte correlación (|r| >= 0.7)
print("Strong correlations - student_mat:")
print(eda_mat$correlation$strong)
print("Strong correlations - student_por:")
print(eda_por$correlation$strong)

# Fin del EDA
# ...existing code...
