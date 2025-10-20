library(shiny)
library(shinythemes)  # Para temas modernos
library(rworldmap)
library(dplyr)
library(countrycode)
library(RColorBrewer)

# Colores iniciales
colores_especies <- c("Camélidos" = "#C35D28",
                      "Camélidos_Andinos" = "#338C14",
                      "Equinos (Donkey)" = "#004667",
                      "Equinos (Mare)" = "#0481B9")

ui <- fluidPage(
  theme = shinytheme("flatly"),  # Tema moderno
  
  titlePanel("Mapa interactivo de especies"),
  
  sidebarLayout(
    sidebarPanel(
      style = "background-color: #f8f9fa; border-radius: 10px; padding: 15px;",
      
      h4("Agregar país y especie"),
      textInput("pais_input", "Nombre del país (en inglés):", value = ""),
      selectInput("especie_input", "Selecciona especie:", choices = names(colores_especies)),
      
      br(),
      h5("O crear nueva especie"),
      textInput("nueva_categoria", "Nueva especie:", value = ""),
      actionButton("agregar_categoria", "Agregar categoría", class = "btn btn-success"),
      
      hr(),
      actionButton("agregar", "Agregar país al mapa", class = "btn btn-primary"),
      br(), br(),
      actionButton("reset", "Reiniciar mapa", class = "btn btn-danger"),
      br(), br(),
      downloadButton("descargar", "Descargar mapa PNG", class = "btn btn-info")
    ),
    
    mainPanel(
      style = "padding: 20px;",
      plotOutput("mapa_plot", height = "650px")
    )
  )
)

server <- function(input, output, session) {
  
  # Datos y colores reactivos
  leches <- reactiveVal(data.frame(Pais = character(),
                                   Especie = character(),
                                   stringsAsFactors = FALSE))
  
  colores <- reactiveVal(colores_especies)
  
  # Agregar nueva categoría
  observeEvent(input$agregar_categoria, {
    nueva <- input$nueva_categoria
    if (nueva == "") return()
    
    col_actual <- colores()
    if (!(nueva %in% names(col_actual))) {
      nuevo_color <- brewer.pal(8, "Set2")[sample(1:8, 1)]
      col_actual[nueva] <- nuevo_color
      colores(col_actual)
      
      updateSelectInput(session, "especie_input",
                        choices = names(col_actual),
                        selected = nueva)
      
      showNotification(paste("Categoría agregada:", nueva), type = "message")
    }
  })
  
  # Agregar país y especie
  observeEvent(input$agregar, {
    pais <- input$pais_input
    especie <- input$especie_input
    
    if (pais == "" | especie == "") {
      showNotification("Debes ingresar país y especie.", type = "error")
      return()
    }
    
    iso3 <- countrycode(pais, "country.name", "iso3c")
    if (is.na(iso3)) {
      showNotification("No se reconoció el país. Intenta de nuevo.", type = "error")
      return()
    }
    
    nueva_tabla <- rbind(leches(), data.frame(Pais = iso3, Especie = especie, stringsAsFactors = FALSE))
    leches(nueva_tabla)
    
    showNotification(paste("Agregado:", pais, "->", iso3, "con especie", especie))
  })
  
  # Reiniciar mapa y colores
  observeEvent(input$reset, {
    leches(data.frame(Pais = character(), Especie = character(), stringsAsFactors = FALSE))
    colores(colores_especies)
    updateSelectInput(session, "especie_input", choices = names(colores_especies))
    showNotification("Mapa reiniciado", type = "message")
  })
  
  # Dibujar mapa
  output$mapa_plot <- renderPlot({
    if (nrow(leches()) == 0) {
      mapa_base <- getMap(resolution = "low")
      plot(mapa_base, col = "white", main = "Mapa interactivo de especies", lwd = 0.8)
    } else {
      mapa <- joinCountryData2Map(leches(),
                                  joinCode = "ISO3",
                                  nameJoinColumn = "Pais",
                                  verbose = FALSE)
      mapCountryData(mapa,
                     nameColumnToPlot = "Especie",
                     catMethod = "categorical",
                     addLegend = TRUE,
                     mapTitle = "Distribución de especies",
                     colourPalette = colores())
    }
  })
  
  # Descargar mapa como PNG
  output$descargar <- downloadHandler(
    filename = function() { paste0("mapa_especies.png") },
    content = function(file) {
      png(file, width = 1200, height = 800)
      if (nrow(leches()) == 0) {
        mapa_base <- getMap(resolution = "low")
        plot(mapa_base, col = "white", main = "Mapa interactivo de especies", lwd = 0.8)
      } else {
        mapa <- joinCountryData2Map(leches(),
                                    joinCode = "ISO3",
                                    nameJoinColumn = "Pais",
                                    verbose = FALSE)
        mapCountryData(mapa,
                       nameColumnToPlot = "Especie",
                       catMethod = "categorical",
                       addLegend = TRUE,
                       mapTitle = "Distribución de especies",
                       colourPalette = colores())
      }
      dev.off()
    }
  )
  
}

shinyApp(ui, server)


