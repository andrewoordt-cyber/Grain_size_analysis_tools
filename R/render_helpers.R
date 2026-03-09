# render_helpers.R
# Helper functions for rendering grain size analysis reports

generate_grain_size_report <- function(sample_location, 
                                       author, 
                                       data_files, 
                                       output_name = NULL,
                                       min_replicates = 2,
                                       tool_repo = getOption("grain_size_tools_repo")) {
  
  # Validate inputs
  if (missing(data_files) || length(data_files) == 0) {
    stop("data_files parameter is required. Provide a list of datasets with path, label, and colour.")
  }
  
  if (is.null(tool_repo)) {
    stop("Tool repository path not set. Use: options(grain_size_tools_repo = 'path/to/repo')")
  }
  
  # Generate output name from sample_location if not provided
  if (is.null(output_name)) {
    clean_name <- gsub("[^[:alnum:]_-]", "_", sample_location)
    clean_name <- gsub("_{2,}", "_", clean_name)
    clean_name <- gsub("^_|_$", "", clean_name)
    clean_name <- tolower(clean_name)
    output_name <- paste0(clean_name, "_profile_comparison_report.html")
  }
  
  template_path <- file.path(tool_repo, "R", "soil_profile_comparison.rmd")
  
  # Ensure outputs directory exists
  output_dir <- file.path(getwd(), "outputs")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    message("Created outputs directory: ", output_dir)
  }
  
  # Render the report
  rmarkdown::render(
    input = template_path,
    output_file = file.path(output_dir, output_name),
    knit_root_dir = getwd(),
    params = list(
      sample_location = sample_location,
      author = author,
      data_files = data_files,
      min_replicates = min_replicates
    ),
    quiet = FALSE
  )
  
  message("\n✓ Report generated successfully!")
  message("  Location: ", file.path(output_dir, output_name))
  
  invisible(file.path(output_dir, output_name))
}

create_dataset <- function(path, label, colour) {
  list(path = path, label = label, colour = colour)
}