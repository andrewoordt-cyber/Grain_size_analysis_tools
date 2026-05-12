#' Generate a grain size analysis report
#'
#' Renders the soil profile comparison report template as an HTML file, saved
#' to an `outputs/` subdirectory of the current working directory.
#'
#' @param sample_location Character. Site or location name used in the report title.
#' @param author Character. Author name shown in the report.
#' @param data_files List of dataset configs created with [create_dataset()].
#' @param output_name Character. Output filename (default: derived from `sample_location`).
#' @param min_replicates Integer. Minimum replicates required to include a sample group (default: 2).
#'
#' @return Invisibly returns the path to the generated HTML file.
#' @export
#'
#' @examples
#' \dontrun{
#' generate_grain_size_report(
#'   sample_location = "Site A",
#'   author          = "Your Name",
#'   data_files      = list(
#'     create_dataset("data/run1.txt", "Pre-treatment A", "#4E79A7"),
#'     create_dataset("data/run2.txt", "Pre-treatment B", "#F28E2B")
#'   )
#' )
#' }
generate_grain_size_report <- function(sample_location,
                                       author,
                                       data_files,
                                       output_name = NULL,
                                       min_replicates = 2) {

  if (missing(data_files) || length(data_files) == 0) {
    stop("data_files is required. Provide a list of datasets via create_dataset().")
  }

  if (is.null(output_name)) {
    clean_name <- gsub("[^[:alnum:]_-]", "_", sample_location)
    clean_name <- gsub("_{2,}", "_", clean_name)
    clean_name <- gsub("^_|_$", "", clean_name)
    clean_name <- tolower(clean_name)
    output_name <- paste0(clean_name, "_profile_comparison_report.html")
  }

  template_path <- system.file("rmd", "soil_profile_comparison.Rmd",
                                package = "grainSizeTools")
  if (!nzchar(template_path)) {
    stop("Report template not found. Re-install grainSizeTools.")
  }

  output_dir <- file.path(getwd(), "outputs")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    message("Created outputs directory: ", output_dir)
  }

  rmarkdown::render(
    input         = template_path,
    output_file   = file.path(output_dir, output_name),
    knit_root_dir = getwd(),
    params        = list(
      sample_location = sample_location,
      author          = author,
      data_files      = data_files,
      min_replicates  = min_replicates
    ),
    quiet = FALSE
  )

  message("\nReport generated: ", file.path(output_dir, output_name))
  invisible(file.path(output_dir, output_name))
}

#' Create a dataset configuration
#'
#' Helper to build a single dataset entry for the `data_files` argument of
#' [generate_grain_size_report()].
#'
#' @param path   Character. Path to the tab-delimited instrument export file.
#' @param label  Character. Display name used in all plots and tables.
#' @param colour Character. Hex colour code for this dataset (e.g. `"#4E79A7"`).
#'
#' @return A named list with elements `path`, `label`, and `colour`.
#' @export
#'
#' @examples
#' create_dataset("data/run1.txt", "Pre-treatment A", "#4E79A7")
create_dataset <- function(path, label, colour) {
  list(path = path, label = label, colour = colour)
}

#' Generate a pretreatment comparison report
#'
#' Renders a report from a single instrument export file, comparing grain size
#' distributions across pretreatment methods encoded in the sample name
#' `meta_code` field. Colours are assigned automatically and kept consistent
#' across all plots.
#'
#' @param sample_location Character. Site or location name used in the report title.
#' @param author Character. Author name shown in the report.
#' @param data_file Character. Path to the tab-delimited instrument export file.
#' @param output_name Character. Output filename (default: derived from `sample_location`).
#' @param min_replicates Integer. Minimum replicates required to include a group (default: 2).
#'
#' @return Invisibly returns the path to the generated HTML file.
#' @export
#'
#' @examples
#' \dontrun{
#' generate_pretreatment_report(
#'   sample_location = "Site A",
#'   author          = "Your Name",
#'   data_file       = "data/run1.txt"
#' )
#' }
generate_pretreatment_report <- function(sample_location,
                                         author,
                                         data_file,
                                         output_name = NULL,
                                         min_replicates = 2) {

  if (missing(data_file) || !nzchar(data_file)) {
    stop("data_file is required. Provide a path to the instrument export file.")
  }

  if (is.null(output_name)) {
    clean_name <- gsub("[^[:alnum:]_-]", "_", sample_location)
    clean_name <- gsub("_{2,}", "_", clean_name)
    clean_name <- gsub("^_|_$", "", clean_name)
    clean_name <- tolower(clean_name)
    output_name <- paste0(clean_name, "_pretreatment_comparison_report.html")
  }

  template_path <- system.file("rmd", "pretreatment_comparison.Rmd",
                                package = "grainSizeTools")
  if (!nzchar(template_path)) {
    stop("Report template not found. Re-install grainSizeTools.")
  }

  output_dir <- file.path(getwd(), "outputs")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    message("Created outputs directory: ", output_dir)
  }

  rmarkdown::render(
    input         = template_path,
    output_file   = file.path(output_dir, output_name),
    knit_root_dir = getwd(),
    params        = list(
      sample_location = sample_location,
      author          = author,
      data_file       = data_file,
      min_replicates  = min_replicates
    ),
    quiet = FALSE
  )

  message("\nReport generated: ", file.path(output_dir, output_name))
  invisible(file.path(output_dir, output_name))
}
