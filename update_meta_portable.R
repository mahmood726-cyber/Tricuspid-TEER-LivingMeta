library(httr)
library(xml2)
library(dplyr)
library(stringr)
library(jsonlite)

resolve_project_dir <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) >= 1 && nzchar(args[[1]])) {
    clean_arg <- gsub('^"|"$', "", args[[1]])
    return(normalizePath(clean_arg, winslash = "/", mustWork = FALSE))
  }

  script_arg <- commandArgs(FALSE)
  file_arg <- script_arg[grepl("^--file=", script_arg)]
  if (length(file_arg) > 0) {
    script_path <- sub("^--file=", "", file_arg[[1]])
    return(dirname(normalizePath(script_path, winslash = "/", mustWork = FALSE)))
  }

  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

node_text_or_na <- function(node, xpath) {
  found <- xml_find_first(node, xpath)
  if (inherits(found, "xml_missing") || length(found) == 0) {
    return(NA_character_)
  }

  value <- xml_text(found, trim = TRUE)
  if (!nzchar(value)) {
    return(NA_character_)
  }

  value
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || is.na(x)) {
    return(y)
  }
  x
}

extract_study <- function(article) {
  title <- node_text_or_na(article, ".//ArticleTitle")
  abstract <- node_text_or_na(article, ".//AbstractText")
  author <- node_text_or_na(article, ".//LastName")
  year <- node_text_or_na(article, ".//PubDate/Year")

  if (is.na(year)) {
    medline_date <- node_text_or_na(article, ".//PubDate/MedlineDate")
    year <- str_extract(medline_date %||% "", "\\d{4}")
  }

  combined_text <- paste(title %||% "", abstract %||% "")

  n_match <- str_extract(combined_text, "(?i)(\\d+)\\s+(patients|subjects|enrolled|treated)") %>%
    str_extract("\\d+")

  tr_match <- str_extract(
    abstract %||% "",
    "(?i)(\\d+\\.?\\d*)%\\s+(of patients )?(achieved|had|were)\\s+(TR )?([<=]|less than or equal to|moderate or less)\\s+2\\+?"
  ) %>%
    str_extract("\\d+\\.?\\d*")

  success_match <- str_extract(
    abstract %||% "",
    "(?i)(technical|procedural)\\s+success\\s+(was|of)\\s+(\\d+\\.?\\d*)%"
  ) %>%
    str_extract("\\d+\\.?\\d*")

  device <- "TEER"
  if (str_detect(combined_text, "(?i)TriClip")) {
    device <- "TriClip"
  }
  if (str_detect(combined_text, "(?i)PASCAL")) {
    device <- "PASCAL"
  }

  data.frame(
    author = author,
    year = year,
    title = title,
    device = device,
    n = suppressWarnings(as.numeric(n_match)),
    tr_post = suppressWarnings(as.numeric(tr_match) / 100),
    success = suppressWarnings(as.numeric(success_match) / 100),
    tr_pre = NA_real_,
    abstract_snippet = str_sub(abstract %||% "", 1, 200),
    stringsAsFactors = FALSE
  )
}

project_dir <- resolve_project_dir()
html_file <- file.path(project_dir, "TEER_LIVING_META.html")
snapshot_file <- file.path(project_dir, "pubmed_teer_snapshot.json")

search_query <- URLencode("Tricuspid TEER OR TriClip OR PASCAL tricuspid repair", reserved = TRUE)
search_url <- paste0(
  "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=",
  search_query,
  "&retmax=50&usehistory=y"
)

cat("Searching PubMed for tricuspid TEER studies...\n")
search_res <- GET(search_url)
stop_for_status(search_res)
search_xml <- read_xml(content(search_res, "text", encoding = "UTF-8"))
ids <- xml_find_all(search_xml, ".//Id") %>% xml_text()

if (length(ids) == 0) {
  stop("No studies found.")
}

cat("Found", length(ids), "potential studies. Fetching abstracts and details...\n")
fetch_url <- paste0(
  "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=",
  paste(ids, collapse = ","),
  "&retmode=xml"
)
fetch_res <- GET(fetch_url)
stop_for_status(fetch_res)
fetch_xml <- read_xml(content(fetch_res, "text", encoding = "UTF-8"))
articles <- xml_find_all(fetch_xml, ".//PubmedArticle")

studies <- bind_rows(lapply(articles, extract_study)) %>%
  filter(!str_detect(coalesce(title, ""), "(?i)review|meta-analysis|editorial|protocol|rationale")) %>%
  filter(!is.na(n))

write_json(
  studies,
  path = snapshot_file,
  auto_unbox = TRUE,
  pretty = TRUE,
  na = "null"
)

cat("Saved structured snapshot to", snapshot_file, "with", nrow(studies), "screened studies.\n")

if (!file.exists(html_file)) {
  cat("Skipping HTML update because", html_file, "was not found.\n")
  quit(save = "no")
}

html_content <- readLines(html_file, warn = FALSE, encoding = "UTF-8")
start_line <- grep("rawData:", html_content)
end_line <- grep("^\\s*],\\s*$", html_content)

if (length(start_line) == 0 || length(end_line[end_line > start_line[1]]) == 0) {
  cat("Skipped HTML injection because no compatible rawData block was found in TEER_LIVING_META.html.\n")
  quit(save = "no")
}

json_data <- toJSON(studies, auto_unbox = TRUE, pretty = TRUE, na = "null")
final_end_line <- end_line[end_line > start_line[1]][1]
new_content <- c(
  html_content[1:(start_line[1] - 1)],
  paste0("            rawData: ", json_data, ","),
  html_content[(final_end_line + 1):length(html_content)]
)

writeLines(new_content, html_file, useBytes = TRUE)
cat("Updated TEER_LIVING_META.html with the latest structured snapshot.\n")
