#' Shiny server for MicheliR
#'
#' @importFrom magrittr %>%
NULL

server <- function(input, output, session) {

  doc_text <- shiny::reactiveVal(NULL)
  doc_pages <- shiny::reactiveVal(NULL)

  results <- shiny::reactiveValues(
    fungus = NULL,
    animals = NULL,
    plants = NULL
  )

  searched <- shiny::reactiveValues(
    fungus = FALSE,
    animals = FALSE,
    plants = FALSE
  )

  ai_result <- shiny::reactiveVal(NULL)
  ai_loading <- shiny::reactiveVal(FALSE)

  # ---- About modal ----
  shiny::observeEvent(input$about_btn, {
    shiny::showModal(
      shiny::modalDialog(
        title = shiny::tags$h2("🍄 MicheliR: An R Toolkit for the Micheli Guide to Fungal Conservation Policy Gap Assessment"),
        shiny::tags$hr(),
        shiny::tags$p(
          shiny::tags$strong("Version:"), " v1.0.0",
          shiny::br(),
          shiny::tags$strong("Authors:"), " Apollon D.M.T. HEGBE / International Society for Fungal Conservation (ISFC)",
          shiny::br(),
          shiny::tags$strong("Copyright:"), " © 2026 ISFC. All rights reserved.",
          shiny::br(),
          shiny::tags$strong("License:"), " MIT (see LICENSE file)"
        ),
        shiny::tags$hr(),
        shiny::tags$p(
          shiny::tags$strong("Description:"),
          "This Shiny application automates the keyword-search and evaluation workflow ",
          "for the Micheli Guide to Fungal Conservation (CBD Evaluation Form). ",
          "It performs deterministic keyword counting with full audit logs, ",
          "and optionally uses the DeepSeek API to filter false positives and answer ",
          "the 5 key questions of the Micheli Guide."
        ),
        shiny::tags$hr(),
        shiny::tags$p(
          shiny::tags$strong("Citation:"),
          "If you use this tool in your research, please cite it as:",
          shiny::tags$br(),
          shiny::tags$em(
            "HEGBE, A. D. M. T. (2026). MicheliR: An R Toolkit for the Micheli Guide to Fungal Conservation Policy Gap Assessment (Version 1.0.0). ",
            "International Society for Fungal Conservation."
          )
        ),
        shiny::tags$hr(),
        shiny::tags$p(
          shiny::tags$strong("Acknowledgements:"),
          "This tool was developed to support the evaluation of National Biodiversity ",
          "Strategy and Action Plans (NBSAPs) and CBD National Reports under the ",
          "Micheli Guide framework."
        ),
        easyClose = TRUE,
        footer = shiny::modalButton("Close")
      )
    )
  })

  # Read file
  shiny::observeEvent(input$file, {
    shiny::req(input$file)
    ext <- tools::file_ext(input$file$name)
    if (ext == "pdf") {
      pages <- pdftools::pdf_text(input$file$datapath)
      doc_text(pages)
      doc_pages(paste0("Page ", seq_along(pages)))
    } else if (ext == "docx") {
      txt <- readtext::readtext(input$file$datapath)$text
      lines <- unlist(strsplit(txt, "\n"))
      lines <- lines[nchar(lines) > 0]
      doc_text(lines)
      doc_pages(paste0("Paragraph ", seq_along(lines)))
    } else if (ext == "txt") {
      lines <- readLines(input$file$datapath, warn = FALSE)
      lines <- lines[nchar(lines) > 0]
      doc_text(lines)
      doc_pages(paste0("Line ", seq_along(lines)))
    } else {
      shiny::showNotification("Unsupported file type", type = "error")
    }
  })

  shiny::observeEvent(input$paste_text, {
    if (nchar(trimws(input$paste_text)) > 0) {
      lines <- unlist(strsplit(input$paste_text, "\n"))
      lines <- lines[nchar(lines) > 0]
      doc_text(lines)
      doc_pages(paste0("Paragraph ", seq_along(lines)))
    }
  })

  # Run keyword search
  run_search <- function(kingdom) {
    shiny::req(doc_text())
    lang <- input$lang
    matches <- analyze_kingdom(doc_text(), doc_pages(), kingdom, lang)
    if (kingdom == "fungus") {
      results$fungus <- matches
      searched$fungus <- TRUE
    } else if (kingdom == "animals") {
      results$animals <- matches
      searched$animals <- TRUE
    } else if (kingdom == "plants") {
      results$plants <- matches
      searched$plants <- TRUE
    }
  }

  shiny::observeEvent(input$search_fungi, { run_search("fungus") })
  shiny::observeEvent(input$search_animals, { run_search("animals") })
  shiny::observeEvent(input$search_plants, { run_search("plants") })
  shiny::observeEvent(input$search_all, {
    run_search("fungus")
    run_search("animals")
    run_search("plants")
  })

  # ---- Main content: show metadata + stats if document loaded, else placeholder ----
  output$main_content <- shiny::renderUI({
    if (is.null(doc_text()) || length(doc_text()) == 0) {
      shiny::div(
        style = "display: flex; justify-content: center; align-items: center; height: 400px;",
        shiny::div(
          style = "text-align: center; padding: 40px; background-color: #f8f9fa; border-radius: 10px;",
          shiny::icon("file-alt", class = "fa-5x", style = "color: #2c3e50; margin-bottom: 20px;"),
          shiny::h3("Please upload a document to begin the assessment."),
          shiny::p("Supported formats: .txt, .pdf, .docx")
        )
      )
    } else {
      shiny::tagList(
        # Metadata display
        shiny::div(
          style = "background-color: #e8f4f8; padding: 12px; border-radius: 5px; margin-bottom: 20px;",
          shiny::fluidRow(
            shiny::column(6, shiny::strong("Document Title: "), shiny::textOutput("display_title", inline = TRUE)),
            shiny::column(3, shiny::strong("Country: "), shiny::textOutput("display_country", inline = TRUE)),
            shiny::column(3, shiny::strong("Date: "), shiny::textOutput("display_date", inline = TRUE))
          ),
          shiny::fluidRow(
            shiny::column(6, shiny::strong("Language: "), shiny::textOutput("display_lang", inline = TRUE))
          )
        ),
        # Stats row: pie chart + table side by side
        shiny::fluidRow(
          shiny::column(6, plotly::plotlyOutput("pie_chart", height = "300px")),
          shiny::column(6,
                        shiny::h4("Frequency Counts", style = "margin-top: 0;"),
                        shiny::tableOutput("summary_stats"))
        ),
        shiny::hr(),
        # Tabs for detailed results
        shiny::tabsetPanel(
          shiny::tabPanel("Fungus",
                          shiny::h4("Frequency Table"),
                          shiny::tableOutput("fungus_table"),
                          shiny::h4("Audit Log"),
                          DT::DTOutput("fungus_audit")),
          shiny::tabPanel("Animals",
                          shiny::h4("Frequency Table"),
                          shiny::tableOutput("animal_table"),
                          shiny::h4("Audit Log"),
                          DT::DTOutput("animal_audit")),
          shiny::tabPanel("Plants",
                          shiny::h4("Frequency Table"),
                          shiny::tableOutput("plant_table"),
                          shiny::h4("Audit Log"),
                          DT::DTOutput("plant_audit")),
          shiny::tabPanel("AI Evaluation",
                          shiny::h4("Micheli Guide Assessment"),
                          shiny::uiOutput("ai_metadata"),
                          shiny::uiOutput("ai_results_ui"),
                          shiny::hr(),
                          shiny::h4("Filtered Audit Logs (AI‑verified)"),
                          DT::DTOutput("ai_filtered_logs"))
        )
      )
    }
  })

  # ---- Display metadata values ----
  output$display_title <- shiny::renderText({ input$doc_title %||% "Not specified" })
  output$display_country <- shiny::renderText({ input$country %||% "Not specified" })
  output$display_date <- shiny::renderText({ as.character(input$doc_date) })
  output$display_lang <- shiny::renderText({ if (input$lang == "en") "English" else "French" })

  # ---- Summary stats and pie chart ----
  totals_reactive <- shiny::reactive({
    c(
      Fungi = if (!is.null(results$fungus)) nrow(results$fungus) else 0,
      Animals = if (!is.null(results$animals)) nrow(results$animals) else 0,
      Plants = if (!is.null(results$plants)) nrow(results$plants) else 0
    )
  })

  output$summary_stats <- shiny::renderTable({
    totals <- totals_reactive()
    total_all <- sum(totals)
    if (total_all == 0) {
      data.frame(Kingdom = c("Fungi", "Animals", "Plants"),
                 Count = c(0,0,0),
                 Percentage = c("0.0%", "0.0%", "0.0%"))
    } else {
      data.frame(Kingdom = c("Fungi", "Animals", "Plants"),
                 Count = totals,
                 Percentage = sprintf("%.1f%%", totals / total_all * 100))
    }
  })

  output$pie_chart <- plotly::renderPlotly({
    totals <- totals_reactive()
    total_all <- sum(totals)
    if (total_all == 0) {
      plotly::plot_ly(
        labels = c("No data"),
        values = c(1),
        type = "pie",
        textinfo = "label",
        hoverinfo = "none",
        marker = list(colors = "#cccccc")
      ) %>%
        plotly::layout(annotations = list(text = "Run a search to see the pie chart", x = 0.5, y = 0.5))
    } else {
      df <- data.frame(
        Kingdom = names(totals),
        Count = totals
      )
      plotly::plot_ly(df, labels = ~Kingdom, values = ~Count, type = "pie",
              textinfo = "label+percent",
              hoverinfo = "label+value+percent",
              marker = list(colors = c("#2c3e50", "#18bc9c", "#f39c12")),
              showlegend = FALSE) %>%
        plotly::layout(title = "Word Frequency Breakdown",
               xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
               yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))
    }
  })

  # ---- Frequency tables and audit logs ----
  output$fungus_table <- shiny::renderTable({
    if (!searched$fungus) return(NULL)
    make_freq_table(results$fungus, fungus_keywords_en)
  })
  output$animal_table <- shiny::renderTable({
    if (!searched$animals) return(NULL)
    make_freq_table(results$animals, animal_keywords_en)
  })
  output$plant_table <- shiny::renderTable({
    if (!searched$plants) return(NULL)
    make_freq_table(results$plants, plant_keywords_en)
  })

  output$fungus_audit <- DT::renderDT({
    if (!searched$fungus || is.null(results$fungus) || nrow(results$fungus) == 0) {
      return(
        DT::datatable(
          data.frame(Message = "Please run the Fungi search to see results."),
          options = list(dom = "t", pageLength = 1),
          rownames = FALSE,
          colnames = ""
        )
      )
    }
    DT::datatable(
      results$fungus[, c("group", "matched", "location", "context_html")],
      colnames = c("Group", "Matched", "Location", "Context"),
      escape = FALSE,
      options = list(pageLength = 20, scrollX = TRUE)
    )
  })

  output$animal_audit <- DT::renderDT({
    if (!searched$animals || is.null(results$animals) || nrow(results$animals) == 0) {
      return(
        DT::datatable(
          data.frame(Message = "Please run the Animals search to see results."),
          options = list(dom = "t", pageLength = 1),
          rownames = FALSE,
          colnames = ""
        )
      )
    }
    DT::datatable(
      results$animals[, c("group", "matched", "location", "context_html")],
      colnames = c("Group", "Matched", "Location", "Context"),
      escape = FALSE,
      options = list(pageLength = 20, scrollX = TRUE)
    )
  })

  output$plant_audit <- DT::renderDT({
    if (!searched$plants || is.null(results$plants) || nrow(results$plants) == 0) {
      return(
        DT::datatable(
          data.frame(Message = "Please run the Plants search to see results."),
          options = list(dom = "t", pageLength = 1),
          rownames = FALSE,
          colnames = ""
        )
      )
    }
    DT::datatable(
      results$plants[, c("group", "matched", "location", "context_html")],
      colnames = c("Group", "Matched", "Location", "Context"),
      escape = FALSE,
      options = list(pageLength = 20, scrollX = TRUE)
    )
  })

  # ---- AI Evaluation ----
  shiny::observeEvent(input$run_ai, {
    shiny::req(doc_text())
    api_key <- input$api_key
    if (is.null(api_key) || api_key == "") {
      api_key <- Sys.getenv("DEEPSEEK_API_KEY")
    }
    if (api_key == "") {
      shiny::showNotification("Please provide a DeepSeek API key or set the DEEPSEEK_API_KEY environment variable.", type = "error")
      return()
    }

    ai_loading(TRUE)
    tryCatch({
      full_text <- paste(doc_text(), collapse = "\n")
      audit_logs <- list(
        fungus = results$fungus,
        animals = results$animals,
        plants = results$plants
      )
      parsed <- call_ai_evaluation(full_text, audit_logs, input$lang, api_key)
      ai_result(parsed)
      shiny::showNotification("AI evaluation completed successfully using DeepSeek.", type = "success")
    }, error = function(e) {
      shiny::showNotification(paste("Error:", e$message), type = "error")
    })
    ai_loading(FALSE)
  })

  output$ai_metadata <- shiny::renderUI({
    shiny::tagList(
      shiny::div(style = "background: #f8f9fa; padding: 10px; border-radius: 5px; margin-bottom: 15px;",
          shiny::strong("Document Title: "), input$doc_title, shiny::br(),
          shiny::strong("Country: "), input$country, shiny::br(),
          shiny::strong("Document Date: "), as.character(input$doc_date), shiny::br(),
          shiny::strong("Language: "), if (input$lang == "en") "English" else "French"
      )
    )
  })

  output$ai_results_ui <- shiny::renderUI({
    res <- ai_result()
    if (is.null(res)) {
      return(shiny::p("Run the AI evaluation to see the Micheli Guide assessment."))
    }
    q_names <- c("1. Were fungi mentioned?",
                 "2. Were fungi clearly recognized as different?",
                 "3. Was strategic consideration given?",
                 "4. Were principal fungal habitats/roles considered?",
                 "5. Was the knowledge gap recognized with a plan?")
    q_keys <- paste0("Q", 1:5)

    rows <- lapply(seq_along(q_keys), function(i) {
      key <- q_keys[i]
      ans <- res[[key]]
      if (is.null(ans)) return(NULL)
      shiny::div(
        shiny::strong(q_names[i]),
        shiny::span("Answer: ", style = "font-weight:bold;"),
        ans$answer,
        shiny::br(),
        shiny::span("Justification: ", style = "font-weight:bold;"),
        ans$justification,
        shiny::hr()
      )
    })

    yes_count <- sum(sapply(q_keys, function(k) {
      ans <- res[[k]]
      if (is.null(ans)) return(0)
      if (toupper(ans$answer) == "YES") 1 else 0
    }))
    rating <- switch(as.character(yes_count),
                     "5" = "Adequate",
                     "4" = "Nearly Adequate",
                     "3" = "Poor",
                     "2" = "Deficient",
                     "1" = "Seriously Deficient",
                     "0" = "Totally Deficient")

    shiny::tagList(
      shiny::h4(paste("Score:", yes_count, "/5 =", rating)),
      shiny::hr(),
      do.call(shiny::tagList, rows),
      shiny::h4("Gold Star Awarded?", ifelse(yes_count == 5, "Yes", "No"))
    )
  })

  output$ai_filtered_logs <- DT::renderDT({
    res <- ai_result()
    if (is.null(res)) {
      return(DT::datatable(data.frame(Message = "No AI evaluation yet.")))
    }
    all_filtered <- data.frame()
    for (kingdom in c("fungus", "animal", "plant")) {
      key <- paste0("filtered_", kingdom, "_audit")
      df <- res[[key]]
      if (!is.null(df) && nrow(df) > 0) {
        df$kingdom <- kingdom
        all_filtered <- rbind(all_filtered, df)
      }
    }
    if (nrow(all_filtered) == 0) {
      return(DT::datatable(data.frame(Message = "No filtered audit entries (all were false positives or none found).")))
    }
    DT::datatable(all_filtered[, c("kingdom", "group", "matched", "location", "context")],
              options = list(pageLength = 20, scrollX = TRUE))
  })

  # ---- Download handler ----
  output$download_results <- shiny::downloadHandler(
    filename = function() {
      paste0("keyword_results_", Sys.Date(), ".zip")
    },
    content = function(file) {
      tmpdir <- tempdir()
      setwd(tmpdir)
      export_list <- list()

      add_kingdom <- function(name, matches, kw_list) {
        if (!is.null(matches) && nrow(matches) > 0) {
          freq <- make_freq_table(matches, kw_list)
          export_list[[paste0(name, "_freq")]] <<- freq
          export_list[[paste0(name, "_audit")]] <<- matches[, c("group", "matched", "location", "context")]
        } else {
          export_list[[paste0(name, "_freq")]] <<- data.frame(Note = "No matches found")
          export_list[[paste0(name, "_audit")]] <<- data.frame(Note = "No matches found")
        }
      }
      add_kingdom("Fungus", results$fungus, fungus_keywords_en)
      add_kingdom("Animals", results$animals, animal_keywords_en)
      add_kingdom("Plants", results$plants, plant_keywords_en)

      totals <- c(
        Fungi = if (!is.null(results$fungus)) nrow(results$fungus) else 0,
        Animals = if (!is.null(results$animals)) nrow(results$animals) else 0,
        Plants = if (!is.null(results$plants)) nrow(results$plants) else 0
      )
      total_all <- sum(totals)
      if (total_all == 0) {
        summary_df <- data.frame(Kingdom = c("Fungi", "Animals", "Plants"),
                                 Count = c(0,0,0),
                                 Percentage = c("0%","0%","0%"))
      } else {
        summary_df <- data.frame(Kingdom = c("Fungi", "Animals", "Plants"),
                                 Count = totals,
                                 Percentage = sprintf("%.1f%%", totals / total_all * 100))
      }
      export_list[["Summary"]] <- summary_df

      metadata_df <- data.frame(
        Field = c("Document Title", "Country", "Document Date", "Language", "Evaluation Date"),
        Value = c(
          input$doc_title,
          input$country,
          as.character(input$doc_date),
          if (input$lang == "en") "English" else "French",
          as.character(Sys.Date())
        ),
        stringsAsFactors = FALSE
      )
      export_list[["Metadata"]] <- metadata_df

      files <- c()
      for (name in names(export_list)) {
        df <- export_list[[name]]
        if (is.null(df)) next
        csv_file <- paste0(name, ".csv")
        write.csv(df, csv_file, row.names = FALSE)
        files <- c(files, csv_file)
      }

      zip(file, files)
    }
  )
}