# Call DeepSeek API for AI evaluation

Call DeepSeek API for AI evaluation

## Usage

``` r
call_ai_evaluation(document_text, audit_logs, lang, api_key)
```

## Arguments

- document_text:

  full document text (character scalar)

- audit_logs:

  list of matches for each kingdom (fungus, animals, plants)

- lang:

  language ("en" or "fr") – currently not used in prompt, but kept for
  future

- api_key:

  DeepSeek API key

## Value

parsed JSON response (list)
