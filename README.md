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

Generates an HTML report comparing one or more soil profile datasets loaded from separate files. The report includes:

- **USDA Soil Texture Triangle** — all datasets plotted by colour, point transparency scaled by depth
- **Depth comparisons** — grain size distributions at each sampled depth across datasets
- **Per-sample replicate plots** — individual replicate curves with D10/D50/D90 CV% tables to assess subsampling consistency

```r
library(grainSizeTools)

generate_grain_size_report(
  sample_location = "My Site",
  author          = "Your Name",
  data_files      = list(
    create_dataset("data/file1.txt", "Label 1", "#4E79A7"),
    create_dataset("data/file2.txt", "Label 2", "#F28E2B"),
    create_dataset("data/file3.txt", "Label 3", "#59A14F")
  ),
  min_replicates = 2
)
```

---

### `generate_pretreatment_report()`

Generates an HTML report comparing multiple pretreatment methods from a **single** instrument export file. Pretreatments are identified by the `meta_code` in each sample name and assigned consistent colours automatically. The report includes:

- **USDA Soil Texture Triangle** — each pretreatment plotted as a different colour
- **Pretreatment comparison plot** — all replicates overlaid, coloured by pretreatment
- **Per-pretreatment plots** — individual replicate curves with D10/D50/D90 CV% tables

```r
library(grainSizeTools)

generate_pretreatment_report(
  sample_location = "My Site",
  author          = "Your Name",
  data_file       = "data/file.txt",
  min_replicates  = 2
)
```

The report is saved to `outputs/` in your working directory.

---

## Sample naming convention

Instrument export sample names must follow this pattern:

```
<sample_id>_<meta_code>_<rep_number>_<optional_note>
```

| Part | Description |
|---|---|
| `sample_id` | Base name including depth value (e.g. `25-CR-R-0.4`) |
| `meta_code` | Single uppercase letter identifying the pretreatment method (see below) |
| `rep_number` | Replicate number (e.g. `2`) |
| `optional_note` | Free text appended after a second underscore (e.g. `sonic`) |

Samples sharing the same `sample_id` and `meta_code` within a dataset are treated as replicates of each other. Ensure depth units are consistent across all datasets (all metres or all centimetres).

### Pretreatment codes

| Code | Description |
|---|---|
| A | No Pretreatment |
| B | H2O2 |
| C | H2O2 then Acetic |
| D | H2O2 then HCl |
| E | Acetic |
| F | Acetic then H2O2 |
| G | HCl |
| H | HCl then H2O2 |
| I | Acetic then Furnace then CBD |
| J | HCl then Furnace then CBD |

---

## Usage templates

Copy the relevant template from `inst/examples/` to your analysis project and customise:

- `generate_report_template.R` — for multi-file soil profile comparisons
- `pretreatment_report_template.R` — for single-file pretreatment comparisons
