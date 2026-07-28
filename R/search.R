#' Search for keywords in text with highlighted context
#'
#' @param text character vector (lines or pages)
#' @param patterns character vector of regex patterns
#' @param group_name display name for the keyword group
#' @param context_window number of characters around the match
#' @param locations optional location labels for each text element
#' @return data.frame with columns: group, matched, location, context, context_html
#' @keywords internal
search_keywords <- function(text, patterns, group_name,
                            context_window = 80, locations = NULL) {
  if (is.null(locations)) {
    locations <- paste0("Line ", seq_along(text))
  }
  combined <- paste(patterns, collapse = "|")
  matches <- data.frame()
  for (i in seq_along(text)) {
    chunk <- text[i]
    if (is.na(chunk) || nchar(chunk) == 0) next
    lower_chunk <- tolower(chunk)
    positions <- stringr::str_locate_all(lower_chunk, tolower(combined))[[1]]
    if (nrow(positions) == 0) next
    for (j in seq_len(nrow(positions))) {
      start <- positions[j, "start"]
      end   <- positions[j, "end"]
      matched_text <- substr(chunk, start, end)
      ctx_start <- max(1, start - context_window)
      ctx_end   <- min(nchar(chunk), end + context_window)
      context_raw <- substr(chunk, ctx_start, ctx_end)
      context_raw <- gsub("\\s+", " ", context_raw)
      rel_start <- start - ctx_start + 1
      rel_end   <- end - ctx_start + 1
      before <- substr(context_raw, 1, rel_start - 1)
      match_part <- substr(context_raw, rel_start, rel_end)
      after <- substr(context_raw, rel_end + 1, nchar(context_raw))
      context_html <- paste0(
        before,
        '<mark style="background-color: #ffff00; font-weight: bold; padding: 0 2px; border-radius: 3px;">',
        match_part,
        '</mark>',
        after
      )
      matches <- rbind(matches, data.frame(
        group = group_name,
        matched = matched_text,
        location = locations[i],
        context = context_raw,
        context_html = context_html,
        stringsAsFactors = FALSE
      ))
    }
  }
  matches
}

#' Analyse a kingdom across document
#'
#' @param text document lines (character vector)
#' @param pages location labels (same length as text)
#' @param kingdom character: "fungus", "animals", or "plants"
#' @param lang character: "en" or "fr"
#' @return data.frame of matches (or empty)
#' @keywords internal
analyze_kingdom <- function(text, pages, kingdom, lang) {
  if (kingdom == "fungus") {
    kw_list <- if (lang == "en") fungus_keywords_en else fungus_keywords_fr
  } else if (kingdom == "animals") {
    kw_list <- if (lang == "en") animal_keywords_en else animal_keywords_fr
  } else if (kingdom == "plants") {
    kw_list <- if (lang == "en") plant_keywords_en else plant_keywords_fr
  } else {
    return(NULL)
  }
  all_matches <- data.frame()
  for (kw in kw_list) {
    res <- search_keywords(text, kw$patterns, kw$name, locations = pages)
    if (nrow(res) > 0) {
      all_matches <- rbind(all_matches, res)
    }
  }
  if (kingdom == "plants") {
    if (nrow(all_matches) > 0) {
      keep <- !(all_matches$group == "Plant" & sapply(all_matches$context, is_industrial_plant))
      all_matches <- all_matches[keep, ]
    }
  }
  all_matches
}

#' Make frequency table from matches
#'
#' @param matches data.frame from search
#' @param all_keywords list of keyword groups (with name element)
#' @return data.frame with Word and Frequency columns, plus TOTAL row
#' @keywords internal
make_freq_table <- function(matches, all_keywords) {
  if (is.null(matches) || nrow(matches) == 0) {
    df <- data.frame(Word = sapply(all_keywords, function(x) x$name),
                     Frequency = 0, stringsAsFactors = FALSE)
    df <- rbind(df, data.frame(Word = "TOTAL", Frequency = 0))
    return(df)
  }
  freq <- table(matches$group)
  df <- data.frame(Word = names(freq), Frequency = as.vector(freq), stringsAsFactors = FALSE)
  all_names <- sapply(all_keywords, function(x) x$name)
  for (nm in all_names) {
    if (!(nm %in% df$Word)) {
      df <- rbind(df, data.frame(Word = nm, Frequency = 0, stringsAsFactors = FALSE))
    }
  }
  df <- df[order(df$Word), ]
  total <- sum(df$Frequency)
  df <- rbind(df, data.frame(Word = "TOTAL", Frequency = total))
  rownames(df) <- NULL
  df
}