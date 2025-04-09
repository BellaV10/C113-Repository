
#install.packages("later")
library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(readr)   # For reading CSV
library(haven)   # For reading SAS files


# UI (User Interface)
ui <- dashboardPage(
  dashboardHeader(title = "C113 Dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Data Table", tabName = "data_table", icon = icon("table"))
    ),
    hr(), # Visual separator
    # Filter controls will be added here dynamically based on columns
    uiOutput("filter_controls")
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "data_table",
        fluidRow(
          box(title = "Lab Report Data", width = 12, DTOutput("report_data_table")),
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
  # Create a reactive data frame with a background color column
  colored_data <- reactive({
    data_to_color <- all_data()
    if (!is.null(data_to_color)) {
      data_to_color$bg_color <- ifelse(grepl("Sample collected Status is not correct", data_to_color$Flag), "lightcoral", NA)
      data_to_color$bg_color <- ifelse(data_to_color$Flag == "Not in EDC", "lightpeach", data_to_color$bg_color)
    }
    data_to_color
  })
  
  # Dynamically create filter controls
  output$filter_controls <- renderUI({
    data_for_filters <- all_data()
    if (!is.null(data_for_filters)) {
      filter_list <- lapply(names(data_for_filters), function(col_name) {
        if (is.character(data_for_filters[[col_name]]) || is.factor(data_for_filters[[col_name]])) {
          selectInput(inputId = paste0("filter_", col_name),
                      label = paste("Filter", col_name),
                      choices = c("All", unique(data_for_filters[[col_name]])),
                      multiple = TRUE,
                      selectize = TRUE)
        }
      })
      tagList(filter_list)
    }
  })
  
  # Filter the data based on user selections
  filtered_data <- reactive({
    data_to_filter <- colored_data() # Use the colored data for filtering
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
      data_to_filter <- data_to_filter %>%
            select("Subject ID", "Visit in EDC", "Visit Number", "Sample Collection Date", "Lab Draw Date", "Flag")
    }
    print("filtered_data() - After filtering with bg_color:")
    print(head(data_to_filter))
    data_to_filter
  })
  
  # Apply color coding and display the table
  output$report_data_table <- renderDT({
    data_to_render <- filtered_data()
    print("renderDT() - Data to render:")
    print(head(data_to_render))
    print("Column names in data_to_render:")
    print(names(data_to_render))
    req(data_to_render)
    datatable(data_to_render) # Basic datatable with no options or styling
  })
   
    # %>%
    #   formatStyle(
    #     'Flag',
    #     target = 'row',
    #     backgroundColor = JS(
    #       'function(row, data, index) {
    #         if (data[ which(Object.keys(data).map(function(key){ return key === "Flag";}) == true) ] && data[ which(Object.keys(data).map(function(key){ return key === "Flag";}) == true) ].includes("Sample collected Status is not correct")) {
    #           return "lightcoral";
    #         }
    #         return "";
    #       }'
    #     )
    #   )
  
}


 
  # Filter the data based on user selections
  

# Run the Shiny app
shinyApp(ui, server)
