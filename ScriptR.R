# -*- coding: utf-8 -*-
# nolint: start
# Configurar opciones de visualización
options(width = 150)  # Aumentar el ancho de la consola
options(max.print = 1000)  # Aumentar el número máximo de líneas a imprimir
options(stringsAsFactors = FALSE)  # Manejar mejor los strings
options(scipen = 999)  # Evitar notación científica


# Configurar la codificación de caracteres a UTF-8 (Opcional, depende del sistema operativo) #nolint

# Sys.setlocale("LC_ALL", "es_ES.UTF-8")  # Asegura el uso de UTF-8 en español en sistemas compatibles #nolint

# Cargar librerías necesarias
library(ggplot2)

# Definición de los datos de la muestra
# x: Número de policías en diferentes pueblos
# y: Número de delitos registrados en esos pueblos

# Lectura de datos
datos_url <- "https://raw.githubusercontent.com/Centromagis/metodosySIM3_V2/refs/heads/main/datos_MetySim/dat_pueblos.txt"
datos <- read.table(file = datos_url, header = TRUE)

# Mostrar solo las primeras filas para evitar salidas grandes en consola
head(datos)
# Cálculo del coeficiente de correlación de Pearson
correlacion_pearson <- cor(datos$Policias, datos$Delitos, method = "pearson")


# Mostrar el coeficiente de correlación con un mensaje descriptivo
cat("Coeficiente de correlación de Pearson:", round(correlacion_pearson, 4), "\n")

# Generación del gráfico de dispersión con línea de tendencia
grafico_dispersion <- ggplot(datos, aes(x = Policias, y = Delitos)) +
  geom_point(size = 3, color = "blue") +  # Puntos de los datos en color azul
  geom_smooth(method = "lm", se = FALSE, color = "red", linetype = "dashed") +  # Línea de regresión lineal en rojo punteado #nolint
  labs(title = "Relación entre Número de Policías y Delitos",
       x = "Número de Policías",
       y = "Número de Delitos") +
  # nolint: next_line
  theme_minimal()  # Aplicar un diseño limpio al gráfico

grafico_dispersion

# Renderizar el Rmd solo si rmarkdown está instalado y pandoc disponible
if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available()) {
  tryCatch(
    rmarkdown::render("Analisis_Policia_Delitos.Rmd"),
    error = function(e) message("No se pudo renderizar Rmd: ", e$message)
  )
} else {
  message("rmarkdown o pandoc no disponible: omitiendo renderizado del Rmd.")
}
