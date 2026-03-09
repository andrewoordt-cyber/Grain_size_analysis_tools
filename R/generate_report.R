# generate_report_template.R
# Copy this file to your analysis project and customize

# Set the tool repo location
options(grain_size_tools_repo = "C:/Users/andre/Documents/R/Grain_size_analysis_tools")

# Load helper
source("C:/Users/andre/Documents/R/Grain_size_analysis_tools/R/render_helpers.R")

# Generate report
generate_grain_size_report(
  sample_location = "YOUR_SITE_NAME_HERE",
  author = "Andrew Oordt",
  data_files = list(
    create_dataset("data/file1.txt", "Dataset 1 Label", "#4E79A7"),
    create_dataset("data/file2.txt", "Dataset 2 Label", "#F28E2B"),
    create_dataset("data/file3.txt", "Dataset 3 Label", "#59A14F")
  ),
  min_replicates = 2
)