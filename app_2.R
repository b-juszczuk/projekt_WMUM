library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(corrplot)

# Wczytanie danych
Dataset_clean <- read.csv("C:\\Users\\Dell\\Desktop\\studia_IAD\\Wdrazanie modeli uczenia maszynowego\\projekt_WMUM\\date.csv", header = TRUE, sep = ",", quote = '"')

# Definicja interfejsu użytkownika (UI)
ui <- dashboardPage(
  skin = "purple",
  dashboardHeader(title = "Kursy Walut"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Opis", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Statystyki opisowe", tabName = "reports", icon = icon("file")),
      menuItem("Wizualizacje", tabName = "analytics", icon = icon("chart-line")),
      menuItem("Zależności", tabName = "settings", icon = icon("exchange-alt")),
      menuItem("Predykcja", tabName = "reports2", icon = icon("dollar-sign"))
    )
  ),
  dashboardBody(
    # Zawartość dashboardu
    tabItems(
      tabItem(tabName = "dashboard",
              h2("Opis"),
              box(withSpinner(DTOutput("Data")), width = 12)
      ),
      tabItem(tabName = "reports",
              h2("Statystyki opisowe"),
              fluidRow(
                box(
                  title = "Tabela Statystyk Opisowych",
                  DT::dataTableOutput("table")
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
              box(width = "100%",  # <- Dodano szerokość
                  title = "Wykres waluty w czasie", background = "maroon", solidHeader = TRUE,
                  plotOutput("currencyTimePlot", width = "100%")  # <- Dodano width = "100%"
              )
      ),
      tabItem(tabName = "settings",
              h2("Zależności"),
              # fluidRow(
              #   column(width = 12,
              #          box(
              #            title = "Wybór walut",
              #            fluidRow(
              #              column(width = 6, selectInput("currency1", "Waluta 1:", choices = colnames(Dataset_clean)[-1])),
              #              column(width = 6, selectInput("currency2", "Waluta 2:", choices = colnames(Dataset_clean)[-1]))
              #            )
              #          )
              #   )
              # ),
              fluidRow(
                # column(width = 6,
                #        box(
                #          title = "Wykres zależności dwóch walut",
                #          plotlyOutput("currencyPlot"),
                #          width = NULL
                #        )
                # ),
                column(width = "100%",
                       box(
                         title = "Macierz korelacji",
                         withSpinner(plotOutput("Corr"),width = "100%"),
                         width = NULL
                       )
                )
              )
      ),
      tabItem(tabName = "reports2",
              h2("Predykcja")
      )
    )
  )
)

# Definicja funkcji serwera (Server)
server <- function(input, output, session) {
  
  # Renderowanie danych
  output$Data <- renderDT({
    DT::datatable(Dataset_clean)
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
    
    # Filtrowanie danych na podstawie daty i wybranej waluty
    filtered_data <- Dataset_clean %>%
      filter(Data >= input$start_date & Data <= input$end_date)
    
    # Rysowanie wykresu
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
    corrplot(cormat, type = "lower", order = "hclust", method = "number")
  })
  
  # Funkcja shinyApp, która uruchamia aplikację
}

# Uruchomienie aplikacji Shiny
shinyApp(ui, server)
