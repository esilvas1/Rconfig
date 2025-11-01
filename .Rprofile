options(radian.auto_match = FALSE)
options(radian.auto_indentation = FALSE)
options(radian.complete_while_typing = FALSE)

# Configuración para VS Code y httpgd
if (interactive() && Sys.getenv("TERM_PROGRAM") == "vscode") {
  if ("httpgd" %in% .packages(all.available = TRUE)) {
    options(vsc.rstudioapi = TRUE)
    options(vsc.use_httpgd = TRUE)
    options(vsc.plot = FALSE)
    options(device = function(...) {
      httpgd::hgd(host = "127.0.0.1", port = 0, silent = FALSE)
      httpgd::hgd_view()
    })
    
    # Configuraciones adicionales para R Markdown
    options(repos = c(CRAN = "https://cran.rstudio.com/"))
    options(tidyverse.quiet = TRUE)
    
    # Configurar Pandoc si está disponible
    pandoc_paths <- c(
      "C:/Users/ESILVAS/AppData/Local/Pandoc",
      "C:/Program Files/Pandoc",
      "C:/Program Files (x86)/Pandoc"
    )
    
    for (path in pandoc_paths) {
      if (file.exists(file.path(path, "pandoc.exe"))) {
        Sys.setenv(RSTUDIO_PANDOC = path)
        message("✓ Pandoc configurado en: ", path)
        break
      }
    }
    
    cat("✓ httpgd configurado para VS Code\n")
    cat("✓ Pandoc disponible:", rmarkdown::pandoc_available(), "\n")
  }
}

# Configuración para knitr/R Markdown
if (requireNamespace("knitr", quietly = TRUE)) {
  knitr::opts_chunk$set(
    fig.width = 8,
    fig.height = 6,
    fig.retina = 2,
    dev = "png",
    warning = FALSE,
    message = FALSE,
    cache = FALSE
  )
}
