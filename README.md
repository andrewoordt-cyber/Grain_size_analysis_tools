# Grain_size_analysis_tools
This is a repo to store tools I build for analyzing grain size data from the laser particle size analyzer (LPSA).

## Tools Available 
**soil_profile_comparison.Rmd**
- this is a tool to compare multiple soil profile datasets.
- It plots samples on a USDA soil textural triangle.
- It compares samples from specific depths across datasets (useful for comparing different pretreatment methods)
- Its looks at grain size analysis for each samples  and its replicates and calculates the Coefficient of Variation to ensure proper subsampling. 
- It was initially developed for the purpose of comparing a single profile that underwent different pretreatment methods prior to  LPSA analysis.
- I can also be useful for analysis of a single dataset. 

To render soil_profile_comparison.Rmd from another project use the following code:
```r
# generate_report.R in your analysis project

# Set the tool repo location once
options(grain_size_tools_repo = "C:/Users/andre/Documents/R/Grain_size_analysis_tools")

# Load helper
source("C:/Users/andre/Documents/R/Grain_size_analysis_tools/R/render_helpers.R")

# Generate the report - super clean and simple!
generate_grain_size_report(
  sample_location = "Radovin",
  author = "Andrew Oordt",
  data_files = list(
    create_dataset("data/dataset1.txt", 
                   "Data Set 1", 
                   "#4E79A7"),
    create_dataset("data/dataset2.txt", 
                   "Data Set 2",
                   "#F28E2B"),
    create_dataset("data/dataset2.txt", 
                   "Data Set 2",
                   "#59A14F")
  ),
  min_replicates = 2
)
```
