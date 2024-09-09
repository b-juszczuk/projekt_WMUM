# Wizualizacja za pomocą Shiny

To repozytorium zawiera projekt na zaliczenie zajęć z "Wdrażania modeli uczenia maszynowego". Zaprezentowana aplikacja powstał przy użyciu pakietu shiny w języku R.

# Wstęp
Aplikacja R Shiny przedstawia jak wygląda zbiór danych, podstawowe statystyki zbioru, interaktywne wizualizacje oraz przewidywanie przyszłego kursu wybranej waluty w stosunku do Euro.

## Uruchomienie 
Aby uruchomić aplikacje należy pobrać plik `date.csv` zawierający zbiór danych oraz plik `app_2.R`, który zawiera samą aplikację shiny. Następnie należy otworzyć plik `app_2.R` w programie RStudio i uruchomić wszystkie polecenia.

> :warning: **Ostrzeżenie:**
>
> Po uruchomieniu wszystkich poleceń aplikacja otworzy się w nowym oknie. Jeśli wykresy nie załadują się natychmiast, proszę o chwilę cierpliwości; aplikacja może potrzebować czasu na pełne załadowanie danych lub przetworzenie informacji.

## Opis aplikacji 
Pierwsza zakładka zawiera krótki opis zbioru oraz przedstawia tabelę z danymi. W prawym górnym rogu znajduje się wyszukiwarka, za pomocą której możemy przeszukiwać dane we wszystkich kolumnach.

![image](https://github.com/b-juszczuk/projekt_WMUM/assets/115696513/6d5388a8-969d-4f2a-95a7-0a11528a1d80)

Druga zakładka zawiera podstawowe statystyki opisowe walut. System automatycznie uwzględnia wszystkie dostępne waluty. Użytkownicy mają również możliwość zarządzania walutami poprzez ich dodawanie i usuwanie według własnych preferencji. Aby usunąć wybraną walutę, wystarczy kliknąć na nią i użyć klawisza 'backspace'. Usunięte waluty zostaną automatycznie przeniesione do listy opcji, którą można znaleźć po kliknięciu w pole wyboru walut. Z tej listy można ponownie wybrać dowolną walutę, aby ją przywrócić.

![image](https://github.com/b-juszczuk/projekt_WMUM/assets/115696513/2c4c0694-4820-49a1-9fb1-a93bda435bc2)

Trzecia zakładka `Wizualizacje` prezentuje dynamiczne narzędzia do analizy danych dotyczących kursów walut. Umożliwia generowanie wykresu przedstawiającego zmiany kursu wybranej waluty w określonym okresie czasu oraz analizę rozkładu wartości wybranej waluty.

![image](https://github.com/b-juszczuk/projekt_WMUM/assets/115696513/f73b5628-777b-462b-b907-f45a88f77457)
![image](https://github.com/b-juszczuk/projekt_WMUM/assets/115696513/e828290a-9f34-4eea-944c-0034bfda3334)

Czwarta zakładka zawiera macierz korelacji dla wszystkich walut ze zbioru.

![image](https://github.com/b-juszczuk/projekt_WMUM/assets/115696513/5d3c989c-887a-44f4-bf54-59c4bdb54c96)

W ostatniej karcie użytkownik ma możliwość wyboru daty oraz waluty, którą chce przeanalizować. Dodatkowo, można wybrać preferowany model predykcyjny, który automatycznie dokonuje prognozy ceny tej waluty na określony dzień.

![image](https://github.com/b-juszczuk/projekt_WMUM/assets/115696513/782dd01e-3df2-47bf-ab10-d2fe31ea5e92)


# Bibliografia:

- https://dax44.github.io/ModelsDeployment/wyk5.html,
- https://github.com/amitvkulkarni/Interactive-Modelling-with-Shiny/tree/main,
- https://rstudio.github.io/shinydashboard/structure.html#background-shiny-and-html,
- https://www.kaggle.com/datasets/lsind18/euro-exchange-daily-rates-19992020
