library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(corrplot)
library(ggplot2)
library(bslib)
library(gridlayout)
library(datasets)
library(rstatix)
library(shinycssloaders)
library(dplyr)
library(rpart)
library(lubridate)

Dataset_clean <- read.csv("C:\\Users\\Dell\\Desktop\\studia_IAD\\Wdrazanie modeli uczenia maszynowego\\projekt_WMUM\\date.csv", header = TRUE, sep = ",", quote = '"')

ui <- dashboardPage(
  skin = "purple",
  dashboardHeader(title = "Kursy Walut"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Opis", tabName = "dashboard", icon = icon("book")),
      menuItem("Statystyki opisowe", tabName = "reports", icon = icon("file")),
      menuItem("Wizualizacje", tabName = "analytics", icon = icon("chart-line")),
      menuItem("Macierz korelacji", tabName = "settings", icon = icon("exchange-alt")),
      menuItem("Predykcja", tabName = "reports2", icon = icon("dollar-sign"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "dashboard",
              tags$h2(style = "font-weight: bold;", "Opis zbioru"),
              box(
                "Zbiór zawiera 9230 obserwacji o kursie 12 walut w stosunku do Euro przedstawionych na przestrzeni czasu od 04.01.1999r. do 11.04.2024r. 
                 Dane pochodzą z European Central Bank Statistical Data WareHouse, EXR - Exchange Rates i zostały zebrane w celu analizy zmian kursów walutowych w czasie.",
                width = 12
              ),
              box(withSpinner(DTOutput("Data")), width = 12, style = "overflow-x: scroll; height: 500px;")
      ),
      tabItem(tabName = "reports",
              tags$h2(style = "font-weight: bold;", "Statystyki opisowe"),
              fluidRow(
                column(width = 12,
                       selectInput("selected_variables", "Wybierz zmienne:", choices = colnames(Dataset_clean)[-1], selected = colnames(Dataset_clean)[-1], multiple = TRUE, width = "100%")
                )
              ),
              fluidRow(
                box(
                  DTOutput("table"),
                  width = 12,
                  style = "overflow-x: height: 500px;"
                )
              )
      ),
      tabItem(tabName = "analytics",
              tags$h2(style = "font-weight: bold;", "Wizualizacje"),
              fluidRow(
                column(width = 12, tabsetPanel(
                  tabPanel("Wykres waluty w czasie",
                           fluidRow(style = "margin-top: 20px;",
                                    column(width = 4, selectInput("currency", "Waluta:", choices = colnames(Dataset_clean)[-1])),
                                    column(width = 4, dateInput("start_date", "Data początkowa:", value = min(Dataset_clean$Data), min = min(Dataset_clean$Data), max = max(Dataset_clean$Data))),
                                    column(width = 4, dateInput("end_date", "Data końcowa:", value = max(Dataset_clean$Data), min = min(Dataset_clean$Data), max = max(Dataset_clean$Data)))
                           ),
                           box(width = "100%",  
                               title = "Wykres waluty w czasie", background = "maroon", solidHeader = TRUE,
                               plotOutput("currencyTimePlot", width = "100%")  
                           )
                  ),
                  tabPanel("Rozkład waluty",
                           fluidRow(style = "margin-top: 20px;",
                                    column(width = 6, selectInput("dist_currency", "Waluta:", choices = colnames(Dataset_clean)[-1])),
                                    column(width = 6, sliderInput("bins", "Liczba przedziałów:", min = 10, max = 100, value = 30))
                           ),
                           box(width = "100%",
                               title = "Histogram rozkładu waluty", background = "black", solidHeader = TRUE,
                               plotOutput("distPlot", width = "100%")
                           )
                  )
                ))
              )
      ),
      tabItem(tabName = "settings",
              tags$h2(style = "font-weight: bold;", "Macierz korelacji"),
              fluidRow(
                column(width = 12,
                       box(
                         withSpinner(plotOutput("Corr", height = "600px", width = "100%")),
                         width = 12,
                         height = "600px"
                       )
                )
              )
      ),
      tabItem(tabName = "reports2",
              tags$h2(style = "font-weight: bold;", "Predykcja"),
              fluidRow(
                column(width = 3, dateInput("input_date", "Wybierz datę:", value = min(Dataset_clean$Data), min = min(Dataset_clean$Data), max = max(Dataset_clean$Data))),
                column(width = 3, selectInput("currency_pred", "Waluta:", choices = colnames(Dataset_clean)[-1])),
                column(width = 3, selectInput("model_type", "Model:", choices = c("Regresja liniowa" = "lm", "Drzewo decyzyjne" = "tree")))
              ),
              box(width = "100%",
                  title = "Prognoza",
                  status = "success",
                  solidHeader = TRUE,
                  textOutput("prediction_output")
              ),
              box(width = "100%",
                  title = "Mean Absolute Error (MAE)",
                  status = "primary",
                  solidHeader = TRUE,
                  textOutput("mae_output")
              )
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Renderowanie danych
  output$Data <- renderDT({
    DT::datatable(Dataset_clean)
  })
  
  # Renderowanie tabeli statystyk opisowych
  output$table <- renderDataTable({
    req(input$selected_variables)
    numeric_data <- Dataset_clean[, c("Data", input$selected_variables)]
    
    stats_df <- data.frame(
      Kolumna = character(),
      Min = numeric(),
      Q1 = numeric(),
      Median = numeric(),
      Mean = numeric(),
      Q3 = numeric(),
      Max = numeric(),
      SD = numeric()
    )
    
    for (col in input$selected_variables) {
      stats <- summary(numeric_data[[col]])
      sd_value <- sd(numeric_data[[col]], na.rm = TRUE)
      stats_df <- rbind(stats_df, c(col, round(stats["Min."], 2), round(stats["1st Qu."], 2), round(stats["Median"], 2), round(stats["Mean"], 2), round(stats["3rd Qu."], 2), round(stats["Max."], 2), round(sd_value, 2)))
    }
    
    colnames(stats_df) <- c("Kolumna", "Min", "Q1", "Median", "Mean", "Q3", "Max", "SD")
    
    DT::datatable(stats_df, options = list(scrollX = TRUE, scrollY = '400px', pageLength = 12))
  })
  
  # Filtracja danych na podstawie wyboru użytkownika
  filteredData <- reactive({
    req(input$start_date, input$end_date)
    Dataset_clean %>%
      filter(Data >= input$start_date & Data <= input$end_date)
  })
  
  # Wykres waluty w czasie
  output$currencyTimePlot <- renderPlot({
    req(input$currency, input$start_date, input$end_date)
    
    filtered_data <- Dataset_clean %>%
      filter(Data >= input$start_date & Data <= input$end_date)
    
    if (nrow(filtered_data) > 0) {
      ggplot(filtered_data, aes(x = Data, y = !!sym(input$currency))) +
        geom_point() +
        labs(x = "Data", y = input$currency) 
    } else {
      plot.new()
      text(0.5, 0.5, "Brak danych w wybranym przedziale czasowym")
    }
  })
  
  # Obliczanie macierzy korelacji
  output$Corr <- renderPlot({
    numeric_cols <- sapply(Dataset_clean, is.numeric)
    cormat <- cor(Dataset_clean[, numeric_cols])
    corrplot(cormat, type = "lower", order = "hclust", method = "number",
             col = colorRampPalette(c("red", "violet", "blue"))(200),
             addCoef.col = "black",
             tl.col = "black"
    )
  })
  
  # Predykcja wartości na podstawie wybranej daty i modelu
  output$prediction_output <- renderText({
    req(input$input_date, input$currency_pred, input$model_type)
    
    # Przekształcanie daty na liczbę dni od daty początkowej
    Dataset_clean$Days <- as.numeric(as.Date(Dataset_clean$Data) - min(as.Date(Dataset_clean$Data)))
    input_date <- as.Date(input$input_date)
    input_days <- as.numeric(input_date - min(as.Date(Dataset_clean$Data)))
    
    # Tworzenie formuły dla wybranego modelu
    formula <- as.formula(paste(input$currency_pred, "~ Days"))
    
    # Tworzenie i trenowanie modelu
    if (input$model_type == "tree") {
      model <- rpart(formula, data = Dataset_clean)
    } else if (input$model_type == "lm") {
      model <- lm(formula, data = Dataset_clean)
    }
    
    # Prognoza wartości
    predicted_value <- predict(model, data.frame(Days = input_days))
    
    # Zwracanie prognozowanej wartości
    if (length(predicted_value) > 0) {
      paste("Prognozowana wartość dla ", input$currency_pred, " na dzień ", input$input_date, " to : ", round(predicted_value, 4))
    } else {
      "Brak wystarczających danych do przeprowadzenia predykcji."
    }
  })
  
  # Obliczanie MAE dla modelu
  output$mae_output <- renderText({
    req(input$input_date, input$currency_pred, input$model_type)
    
    # Przekształcanie daty na liczbę dni od daty początkowej
    Dataset_clean$Days <- as.numeric(as.Date(Dataset_clean$Data) - min(as.Date(Dataset_clean$Data)))
    
    # Tworzenie formuły dla wybranego modelu
    formula <- as.formula(paste(input$currency_pred, "~ Days"))
    
    # Tworzenie i trenowanie modelu
    if (input$model_type == "tree") {
      model <- rpart(formula, data = Dataset_clean)
      model_name <- "Drzewo decyzyjne"
    } else if (input$model_type == "lm") {
      model <- lm(formula, data = Dataset_clean)
      model_name <- "Regresja liniowa"
    }
    
    # Prognoza wartości dla wszystkich dni w zbiorze danych
    predicted_values <- predict(model, Dataset_clean)
    
    # Obliczanie MAE
    actual_values <- Dataset_clean[[input$currency_pred]]
    mae <- mean(abs(predicted_values - actual_values), na.rm = TRUE)
    
    if (!is.na(mae)) {
      paste("Mean Absolute Error (MAE) dla modelu ", model_name, " to : ", round(mae, 4))
    } else {
      "Brak wystarczających danych do obliczenia MAE."
    }
  })
  
  # Rozkład waluty
  output$distPlot <- renderPlot({
    req(input$dist_currency, input$bins)
    
    ggplot(Dataset_clean, aes_string(input$dist_currency)) +
      geom_histogram(bins = input$bins, fill = "blue", color = "black") +
      labs(x = input$dist_currency, y = "Częstotliwość")
  })
}

shinyApp(ui, server)
