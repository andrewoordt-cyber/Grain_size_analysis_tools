# render_helpers.R
# Helper functions for rendering grain size analysis reports

generate_grain_size_report <- function(sample_location, 
                                       author, 
                                       data_files, 
                                       output_name = NULL,  # Now optional
                                       min_replicates = 2,
                                       template_path = NULL) {
  
  # Validate inputs
  if (missing(data_files) || length(data_files) == 0) {
    stop("data_files parameter is required. Provide a list of datasets with path, label, and colour.")
  }
  
  # Generate output name from sample_location if not provided
  if (is.null(output_name)) {
    # Clean the sample location for use as filename
    clean_name <- gsub("[^[:alnum:]_-]", "_", sample_location)  # Replace non-alphanumeric with underscore
    clean_name <- gsub("_{2,}", "_", clean_name)  # Replace multiple underscores with single
    clean_name <- gsub("^_|_$", "", clean_name)  # Remove leading/trailing underscores
    clean_name <- tolower(clean_name)  # Convert to lowercase
    output_name <- paste0(clean_name, "_profile_comparison_report.html")
  }
  
  # If template path not provided, assume it's in the same directory as this helper
  if (is.null(template_path)) {
    template_path <- file.path(dirname(sys.frame(1)$ofile), "soil_profile_comparison.rmd")
  }
  
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
  
  # Success message
  message("\n✓ Report generated successfully!")
  message("  Location: ", file.path(output_dir, output_name))
  
  # Return path invisibly for programmatic use
  invisible(file.path(output_dir, output_name))
}

# Helper to create dataset entries
create_dataset <- function(path, label, colour) {
  list(path = path, label = label, colour = colour)
}