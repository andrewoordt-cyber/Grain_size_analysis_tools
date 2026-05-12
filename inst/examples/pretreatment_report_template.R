# pretreatment_report_template.R
# Copy this file to your analysis project and customise the parameters below.
#
# Use this report when all pretreatment data is in a single instrument export
# file. Pretreatments are identified by the meta_code in each sample name
# (<sample_id>_<meta_code>_<rep_number>).
#
# Install the package once:
#   devtools::install_local("C:/Users/andre/Documents/R/Grain_size_analysis_tools")

library(grainSizeTools)

generate_pretreatment_report(
  sample_location = "YOUR_SITE_NAME_HERE",
  author          = "Andrew Oordt",
  data_file       = "data/your_file.txt",
  min_replicates  = 2
)
