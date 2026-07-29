# Search for keywords in text with highlighted context

Search for keywords in text with highlighted context

## Usage

``` r
search_keywords(
  text,
  patterns,
  group_name,
  context_window = 80,
  locations = NULL
)
```

## Arguments

- text:

  character vector (lines or pages)

- patterns:

  character vector of regex patterns

- group_name:

  display name for the keyword group

- context_window:

  number of characters around the match

- locations:

  optional location labels for each text element

## Value

data.frame with columns: group, matched, location, context, context_html
