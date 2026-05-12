# grainSizeTools

An R package for analysing and visualising grain size data from laser particle size analysers (LPSA).

## Installation

```r
devtools::install_local("path/to/Grain_size_analysis_tools")
# or, once pushed to GitHub:
devtools::install_github("andrewoordt-cyber/Grain_size_analysis_tools")
```

## Tools Available

### `generate_grain_size_report()`

Generates an HTML report comparing one or more soil profile datasets. The report includes:

- **USDA Soil Texture Triangle** — all datasets plotted by colour, point transparency scaled by depth
- **Depth comparisons** — grain size distributions at each sampled depth across datasets
- **Per-sample replicate plots** — individual replicate curves with D10/D50/D90 CV% tables to assess subsampling consistency

Originally developed to compare a single soil profile processed under different pretreatment methods prior to LPSA analysis, but works equally well for single-dataset analysis or any multi-dataset comparison.

## Usage

Copy `inst/examples/generate_report_template.R` to your analysis project and customise:

```r
library(grainSizeTools)

generate_grain_size_report(
  sample_location = "My Site",
  author          = "Your Name",
  data_files      = list(
    create_dataset("data/file1.txt", "Pre-treatment A", "#4E79A7"),
    create_dataset("data/file2.txt", "Pre-treatment B", "#F28E2B"),
    create_dataset("data/file3.txt", "Pre-treatment C", "#59A14F")
  ),
  min_replicates = 2
)
```

The report is saved to `outputs/` in your working directory.

## Sample naming convention

Instrument export sample names must follow this pattern:

```
<sample_id>_<meta_code>_<rep_number>_<optional_note>
```

| Part | Description |
|---|---|
| `sample_id` | Base name including depth value (e.g. `25-CR-R-0.4`) |
| `meta_code` | Single uppercase letter for treatment/prep method (e.g. `B`) |
| `rep_number` | Replicate number (e.g. `2`) |
| `optional_note` | Free text appended after a second underscore (e.g. `sonic`) |

Samples sharing the same `sample_id` and `meta_code` within a dataset are treated as replicates of each other. Ensure depth units are consistent across all datasets (all metres or all centimetres).
