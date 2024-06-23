library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(corrplot)
library(ggplot2)
library(bslib)
library(gridlayout)
library(datasets)
library(skimr)
library(rstatix)
library(shinycssloaders)
library(dplyr)
library(rpart)

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
              h2("Opis"),
              box(withSpinner(DTOutput("Data")), width = 12, style = "overflow-x: scroll; height: 500px;")
      ),
      tabItem(tabName = "reports",
              h2("Statystyki opisowe"),
              fluidRow(
                box(
                  DTOutput("table"),
                  width = 12,
                  style = "overflow-x: height: 500px;"
                )
              )
      ),
      tabItem(tabName = "analytics",
              h2("Wizualizacje"),
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
              h2("Macierz korelacji"),
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
              h2("Predykcja"),
              fluidRow(
                sidebarPanel(
                  dateInput("input_date", "Wybierz datę:", value = min(Dataset_clean$Data), min = min(Dataset_clean$Data), max = max(Dataset_clean$Data))
                ),
                mainPanel(
                  box(
                    verbatimTextOutput("prediction_output"),
                    width = 12
                  )
                )
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
    numeric_cols <- sapply(Dataset_clean[, -1], is.numeric)
    numeric_data <- Dataset_clean[, c(FALSE, numeric_cols)]
    
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
    
    for (col in names(numeric_data)) {
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
  
  # Predykcja wartości na podstawie wybranej daty
  output$prediction_output <- renderPrint({
    req(input$input_date)
    
    # Aktualizacja train_df i test_df na podstawie input$input_date
    input_date <- as.Date(input$input_date)
    num_train_samples <- round(nrow(Dataset_clean) * .7)
    num_test_samples <- nrow(Dataset_clean) - num_train_samples
    
    train_df <- Dataset_clean[1:num_train_samples, ]
    test_df <- Dataset_clean[(num_train_samples + 1):(num_train_samples + num_test_samples), ]
    
    train_df$Data <- as.Date(train_df$Data)
    test_df$Data <- as.Date(test_df$Data)
    
    # Budowanie modelu drzewa decyzyjnego na nowych danych treningowych
    model_tree <- rpart(Polish.zloty. ~ Data, data = train_df, method = "anova")
    
    # Przewidywanie wartości dla nowej daty
    new_data <- data.frame(Data = input_date)
    prediction <- predict(model_tree, newdata = new_data)
    
    print(paste("Przewidywana wartość Polish.zloty. dla daty", input_date, "to:", prediction))
  })
  
}

shinyApp(ui, server)
