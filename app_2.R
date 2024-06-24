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
      menuItem("Opis", tabName = "dashboard", icon = icon("dashboard")),
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
                "Zbiór zawiera 9230 obserwacji o kursie 12 walut w stosunku do Euro przedstawionych na przestrzeni czasu od 04.01.1999r. do 11.04.2024r.",
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
                column(width = 4, selectInput("currency", "Waluta:", choices = colnames(Dataset_clean)[-1])),
                column(width = 4, dateInput("start_date", "Data początkowa:", value = min(Dataset_clean$Data), min = min(Dataset_clean$Data), max = max(Dataset_clean$Data))),
                column(width = 4, dateInput("end_date", "Data końcowa:", value = max(Dataset_clean$Data), min = min(Dataset_clean$Data), max = max(Dataset_clean$Data)))
              ),
              box(width = "100%",  
                  title = "Wykres waluty w czasie", background = "maroon", solidHeader = TRUE,
                  plotOutput("currencyTimePlot", width = "100%")  
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
                column(width = 3, selectInput("model_type", "Model:", choices = c("Drzewo decyzyjne" = "tree", "Regresja liniowa" = "lm")))
              ),
              box(width = "100%",
                  verbatimTextOutput("prediction_output")),
              box(width = "100%",
                  verbatimTextOutput("mae_output"))
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
  output$prediction_output <- renderPrint({
    req(input$input_date, input$currency_pred, input$model_type)
    
    # Przekształcanie daty na liczbę dni od daty początkowej
    Dataset_clean$Days <- as.numeric(as.Date(Dataset_clean$Data) - min(as.Date(Dataset_clean$Data)))
    input_date <- as.Date(input$input_date)
    input_days <- as.numeric(input_date - min(as.Date(Dataset_clean$Data)))
    
    # Podział danych na dane treningowe i testowe
    set.seed(2024)
    num_train_samples <- round(nrow(Dataset_clean) * .7)
    train_df <- Dataset_clean[1:num_train_samples, ]
    test_df <- Dataset_clean[(num_train_samples + 1):nrow(Dataset_clean), ]
    
    # Przewidywanie wartości dla nowej daty
    new_data <- data.frame(Days = input_days)
    
    if (input$model_type == "tree") {
      # Budowanie modelu drzewa decyzyjnego
      formula_tree <- as.formula(paste(input$currency_pred, "~ Days"))
      model_tree <- rpart(formula_tree, data = train_df, method = "anova")
      prediction <- predict(model_tree, newdata = new_data)
    } else {
      # Budowanie modelu regresji liniowej
      formula_lm <- as.formula(paste(input$currency_pred, "~ Days"))
      model_lm <- lm(formula_lm, data = train_df)
      prediction <- predict(model_lm, newdata = new_data)
    }
    
    print(paste("Przewidywana wartość", input$currency_pred, "dla daty", input_date, "to:", round(prediction, 2)))
  })
  
  # Obliczanie MAE dla wybranego modelu i waluty
  output$mae_output <- renderPrint({
    req(input$currency_pred, input$model_type)
    
    # Przekształcanie daty na liczbę dni od daty początkowej
    Dataset_clean$Days <- as.numeric(as.Date(Dataset_clean$Data) - min(as.Date(Dataset_clean$Data)))
    
    # Podział danych na dane treningowe i testowe
    num_train_samples <- round(nrow(Dataset_clean) * .7)
    train_df <- Dataset_clean[1:num_train_samples, ]
    test_df <- Dataset_clean[(num_train_samples + 1):nrow(Dataset_clean), ]
    
    if (input$model_type == "tree") {
      # Budowanie modelu drzewa decyzyjnego
      formula_tree <- as.formula(paste(input$currency_pred, "~ Days"))
      model_tree <- rpart(formula_tree, data = train_df, method = "anova")
      predictions <- predict(model_tree, newdata = test_df)
    } else {
      # Budowanie modelu regresji liniowej
      formula_lm <- as.formula(paste(input$currency_pred, "~ Days"))
      model_lm <- lm(formula_lm, data = train_df)
      predictions <- predict(model_lm, newdata = test_df)
    }
    
    actuals <- test_df[[input$currency_pred]]
    mae <- mean(abs(predictions - actuals))
    
    print(paste("Mean Absolute Error (MAE) dla modelu", input$model_type, "i waluty", input$currency_pred, "to:", round(mae, 2)))
  })
}


shinyApp(ui, server)
