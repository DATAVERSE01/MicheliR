#' Shiny UI for MicheliR
#'
ui <- shiny::fluidPage(
  theme = shinythemes::shinytheme("flatly"),
  shiny::titlePanel("🍄 MicheliR: An R Toolkit for the Micheli Guide to Fungal Conservation Policy Gap Assessment"),
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::h4("Document Input"),
      shiny::fileInput("file", "Choose a file",
                       accept = c(".txt", ".pdf", ".docx")),
      shiny::helpText("Supported: .txt, .pdf, .docx"),
      shiny::hr(),
      shiny::textAreaInput("paste_text", "Or paste text directly", rows = 4,
                           placeholder = "Paste the document content here..."),
      shiny::hr(),
      shiny::h4("Document Metadata"),
      shiny::textInput("doc_title", "Document Title",
                       placeholder = "e.g., National Biodiversity Strategy and Action Plan"),
      shiny::textInput("country", "Country",
                       placeholder = "e.g., Benin"),
      shiny::dateInput("doc_date", "Document Date", value = Sys.Date()),
      shiny::h4("Document Language"),
      shiny::radioButtons("lang", "Select language of the document",
                          choices = c("English" = "en", "French" = "fr"),
                          selected = "en", inline = TRUE),
      shiny::hr(),
      shiny::h4("Keyword Search"),
      shiny::div(
        style = "display: flex; gap: 10px; flex-wrap: wrap;",
        shiny::actionButton("search_fungi", "🔍 Fungi", class = "btn-primary"),
        shiny::actionButton("search_animals", "🔍 Animals", class = "btn-success"),
        shiny::actionButton("search_plants", "🔍 Plants", class = "btn-warning"),
        shiny::actionButton("search_all", "▶ Run All", class = "btn-info")
      ),
      shiny::hr(),
      shiny::h4("AI Evaluation (DeepSeek)"),
      shiny::textInput("api_key", "DeepSeek API Key",
                       placeholder = "sk-... or set DEEPSEEK_API_KEY env var"),
      shiny::actionButton("run_ai", "🧠 Run AI Evaluation", class = "btn-danger",
                          icon = shiny::icon("robot")),
      shiny::br(), shiny::br(),
      shiny::downloadButton("download_results", "💾 Save Results", class = "btn-secondary"),
      shiny::br(), shiny::br(),
      shiny::actionButton("about_btn", "ℹ️ About", class = "btn-secondary",
                          icon = shiny::icon("info-circle"), width = "100%")
    ),
    shiny::mainPanel(
      shiny::uiOutput("main_content")
    )
  )
)