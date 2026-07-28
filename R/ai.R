#' Call DeepSeek API for AI evaluation
#'
#' @param document_text full document text (character scalar)
#' @param audit_logs list of matches for each kingdom (fungus, animals, plants)
#' @param lang language ("en" or "fr") – currently not used in prompt, but kept for future
#' @param api_key DeepSeek API key
#' @return parsed JSON response (list)
#' @keywords internal
call_ai_evaluation <- function(document_text, audit_logs, lang, api_key) {
  system_prompt <- paste0(
    "You are an expert evaluator applying the Micheli Guide to Fungal Conservation (CBD Evaluation Form). ",
    "You must assess a country's CBD document with forensic precision. ",
    "You are not allowed to give subjective opinions—only evidence-based, verifiable conclusions. ",
    "You must prove your accuracy through audit logs.\n\n",
    "You will receive the full document text and the keyword search audit logs (matches with context). ",
    "First, filter out false positives from the audit logs (e.g., 'fung' in 'fungicide' as a chemical, ",
    "'myc' in 'mycobacterium', or 'plant' in industrial contexts). ",
    "Then, answer the following 5 key questions strictly based on the document:\n",
    "1. Were fungi mentioned? (Yes if the document explicitly contains words like fungi, fungal, lichen, mushroom, yeast, etc. ",
    "   in a biodiversity/conservation context. No if only as exploitable resource or pathogen unless also positive biodiversity mention.)\n",
    "2. Distinct kingdom recognized? (Yes if the document clearly, consistently states fungi are a separate kingdom from plants/animals. ",
    "   No if grouped with flora, plants, or microorganisms without distinction.)\n",
    "3. Strategic consideration given? (Yes if explicit, concrete plans for fungal conservation are present, ",
    "   e.g., Important Fungal Areas, legal protection gaps, Red Lists. General biodiversity plans do not count.)\n",
    "4. Habitats/roles considered? (Yes if specific fungal ecological roles are mentioned in a conservation context: ",
    "   decomposers, mycorrhizal, lichen-forming, parasitic, freshwater/marine fungi, dung fungi, etc.)\n",
    "5. Knowledge gap + plan? (Yes only if the document admits a lack of fungal data AND proposes a concrete action to fix it, ",
    "   e.g., fungal inventory, training, funding. Acknowledging gap without action is No.)\n\n",
    "IMPORTANT: You MUST respond with a valid JSON object only. Do not include any other text outside the JSON.\n",
    "The JSON must have the following structure:\n",
    "{\n",
    "  \"Q1\": {\"answer\": \"Yes/No\", \"justification\": \"...\"},\n",
    "  \"Q2\": {\"answer\": \"Yes/No\", \"justification\": \"...\"},\n",
    "  \"Q3\": {\"answer\": \"Yes/No\", \"justification\": \"...\"},\n",
    "  \"Q4\": {\"answer\": \"Yes/No\", \"justification\": \"...\"},\n",
    "  \"Q5\": {\"answer\": \"Yes/No\", \"justification\": \"...\"},\n",
    "  \"filtered_fungus_audit\": [ list of filtered audit entries for fungus, each with group, matched, location, context ],\n",
    "  \"filtered_animal_audit\": [ ... ],\n",
    "  \"filtered_plant_audit\": [ ... ]\n",
    "}"
  )

  if (nchar(document_text) > 30000) {
    document_text <- substr(document_text, 1, 30000)
    document_text <- paste0(document_text, "\n[... document truncated for length ...]")
  }

  audit_text <- "Audit logs from keyword search (each entry: group | matched word | location | context):\n"
  for (kingdom in c("fungus", "animals", "plants")) {
    logs <- audit_logs[[kingdom]]
    if (!is.null(logs) && nrow(logs) > 0) {
      audit_text <- paste0(audit_text, "\n--- ", toupper(kingdom), " ---\n")
      for (i in 1:nrow(logs)) {
        entry <- logs[i, ]
        audit_text <- paste0(audit_text,
                             entry$group, " | ", entry$matched, " | ", entry$location,
                             " | \"", entry$context, "\"\n")
      }
    } else {
      audit_text <- paste0(audit_text, "\n--- ", toupper(kingdom), " --- No matches found.\n")
    }
  }

  user_message <- paste0(
    "Document text:\n", document_text, "\n\n",
    audit_text
  )

  url <- "https://api.deepseek.com/chat/completions"
  headers <- httr::add_headers(
    `Authorization` = paste("Bearer", api_key),
    `Content-Type` = "application/json"
  )
  body <- list(
    model = "deepseek-v4-pro",
    messages = list(
      list(role = "system", content = system_prompt),
      list(role = "user", content = user_message)
    ),
    temperature = 0.0,
    stream = FALSE
  )

  response <- httr::POST(url, headers, body = jsonlite::toJSON(body, auto_unbox = TRUE))

  if (httr::status_code(response) != 200) {
    error_detail <- httr::content(response, "text")
    stop("DeepSeek API error (Status: ", httr::status_code(response), "): ", error_detail)
  }

  result <- httr::content(response, "parsed")
  json_text <- result$choices[[1]]$message$content
  parsed <- tryCatch({
    jsonlite::fromJSON(json_text)
  }, error = function(e) {
    start <- regexpr("\\{", json_text)
    end <- regexpr("\\}[^}]*$", json_text)
    if (start != -1 && end != -1) {
      json_sub <- substr(json_text, start, end + attr(end, "match.length") - 1)
      return(jsonlite::fromJSON(json_sub))
    } else {
      stop("Failed to parse JSON response from DeepSeek: ", json_text)
    }
  })
  parsed
}