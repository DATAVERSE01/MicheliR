#' Industrial indicators to exclude "plant" used in factories, sewage, etc.
#' @keywords internal
industrial_indicators <- c(
  "factory", "sewage", "treatment", "industrial", "power",
  "manufacturing", "plant and equipment", "plant facility",
  "usine", "industri", "traitement", "station d'épuration",
  "centrale", "équipement"
)

#' Check if a context indicates industrial "plant"
#' @param context character string from text
#' @return logical
#' @keywords internal
is_industrial_plant <- function(context) {
  any(sapply(industrial_indicators, function(ind) {
    grepl(ind, context, ignore.case = TRUE)
  }))
}