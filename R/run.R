#' Launch the MicheliR Shiny App
#'
#' @return Launches the Shiny application
#' @export          
# <-- THIS MUST BE HERE
run_app <- function() {
  options(shiny.maxRequestSize = 100 * 1024^2)   # 100 MB limit
  shiny::shinyApp(ui = ui, server = server)
}
