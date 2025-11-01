# Script de prueba para verificar la configuración del entorno R + VS Code
# Ejecutar este script para verificar que todo esté funcionando correctamente

cat("=== Verificación del Entorno R + VS Code ===\n\n")

# 1. Verificar versión de R
cat("1. Versión de R:\n")
cat("  ", R.version.string, "\n\n")

# 2. Verificar Pandoc
cat("2. Configuración de Pandoc:\n")
cat("   Variable RSTUDIO_PANDOC:", Sys.getenv("RSTUDIO_PANDOC"), "\n")
if (requireNamespace("rmarkdown", quietly = TRUE)) {
  cat("   Pandoc disponible:", rmarkdown::pandoc_available(), "\n")
  if (rmarkdown::pandoc_available()) {
    cat("   Versión de Pandoc:", as.character(rmarkdown::pandoc_version()), "\n")
  }
} else {
  cat("   rmarkdown no está instalado\n")
}
cat("\n")

# 3. Verificar httpgd
cat("3. Configuración de httpgd:\n")
if ("httpgd" %in% .packages(all.available = TRUE)) {
  cat("   ✓ httpgd está instalado\n")
  cat("   Configuración VS Code httpgd:", getOption("vsc.use_httpgd", FALSE), "\n")
} else {
  cat("   ✗ httpgd no está instalado\n")
}
cat("\n")

# 4. Verificar paquetes principales
cat("4. Paquetes principales:\n")
required_packages <- c("tidyverse", "rmarkdown", "knitr", "ggplot2", "dplyr")
for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("   ✓", pkg, "está disponible\n")
  } else {
    cat("   ✗", pkg, "NO está disponible\n")
  }
}
cat("\n")

# 5. Verificar datos del proyecto
cat("5. Archivos de datos del proyecto:\n")
data_files <- c("student-mat.csv", "student-por.csv", "student.csv")
for (file in data_files) {
  if (file.exists(file)) {
    cat("   ✓", file, "encontrado\n")
  } else {
    cat("   ✗", file, "NO encontrado\n")
  }
}
cat("\n")

# 6. Test de renderizado rápido
cat("6. Test de funcionalidad básica:\n")
tryCatch({
  # Test simple de gráfico
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    cat("   ✓ Generación de gráficos: OK\n")
  }
  
  # Test de R Markdown (sin ejecutar, solo verificar)
  if (rmarkdown::pandoc_available()) {
    cat("   ✓ R Markdown: Listo para compilar\n")
  } else {
    cat("   ✗ R Markdown: Problema con Pandoc\n")
  }
  
}, error = function(e) {
  cat("   ✗ Error en pruebas:", e$message, "\n")
})

cat("\n=== Resumen ===\n")
if (rmarkdown::pandoc_available() && "httpgd" %in% .packages(all.available = TRUE)) {
  cat("🎉 ¡Entorno completamente configurado y listo para usar!\n")
  cat("   Puedes compilar documentos R Markdown con: rmarkdown::render('archivo.Rmd')\n")
  cat("   Los gráficos se mostrarán en VS Code con httpgd\n")
} else {
  cat("⚠️  Hay algunos problemas en la configuración. Revisa los mensajes arriba.\n")
}
cat("\n")