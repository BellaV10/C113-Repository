
#install.packages("later")
library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(readr)   # For reading CSV
library(haven)   # For reading SAS files


# UI (User Interface)
load("data/cfl.rData")
ui <- dashboardPage(
  dashboardHeader(title = "C113 Dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Lab Recon", tabName = "data_table", icon = icon("table"))
    ),
    hr(), # Visual separator
    # Filter controls will be added here dynamically based on columns
    uiOutput("filter_controls")
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "data_table",
        fluidRow(
          box(title = "Lab Reconciliation", width = 12, DTOutput("report_data_table")),
          verbatimTextOutput("debug_output") 
        )
      )
    )
  )
)

# Server (Backend Logic)
server <- function(input, output, session) {
  all_data <- reactive({
    print("all_data() is running")
    print(head(cfl))
    cfl
  })
  
  colored_data <- reactive({
    data_to_color <- all_data()
    if (!is.null(data_to_color)) {
      data_to_color$bg_color <- ifelse(grepl("Sample collected Status is not correct", data_to_color$Flag), "lightcoral", NA)
      data_to_color$bg_color <- ifelse(data_to_color$Flag == "Not in EDC", "lightpeach", data_to_color$bg_color)
    }
    data_to_color
  })
  
  output$report_data_table <- renderDT({
    data_to_render <- filtered_data()
    print("renderDT() - Data to render:")
    print(head(data_to_render))
    req(data_to_render)
    
    # Apply formatting based on bg_color
    styled_dt <- datatable(data_to_render) %>%
      formatStyle(
        'Flag',
        backgroundColor = data_to_render$bg_color
      )
    
    # Remove the bg_color column for display
    styled_dt %>% select(-bg_color)
  })
  
  filtered_data <- reactive({
    data_to_filter <- colored_data() # Use colored data
    print("filtered_data() - Initial data with bg_color:")
    print(head(data_to_filter))
    if (!is.null(data_to_filter)) {
      for (col_name in names(data_to_filter)) {
        filter_value <- input[[paste0("filter_", col_name)]]
        if (!is.null(filter_value) && !"All" %in% filter_value) {
          data_to_filter <- data_to_filter %>%
            filter(.data[[col_name]] %in% filter_value)
        }
      }
      print("filtered_data() - After filtering with bg_color:")
      print(head(data_to_filter))
      data_to_filter # Keep bg_color for styling in renderDT
    }
  })
  
  output$report_data_table <- renderDT({
    data_to_render <- filtered_data()
    print("renderDT() - Data to render:")
    print(head(data_to_render))
    print("Column names in data_to_render:")
    print(names(data_to_render))
    req(data_to_render)
    datatable(data_to_render, filter = "top")
  })
}
shinyApp(ui, server)


