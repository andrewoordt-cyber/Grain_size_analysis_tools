# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package overview

`grainSizeTools` is an R package for working with soil profile grain size data from laser particle size analyser (LPSA) instrument exports. It has two independent layers:

- **Report generation** (`R/render_helpers.R`): `generate_grain_size_report()`, `generate_pretreatment_report()`, and `create_dataset()` render full HTML reports from Rmd templates.
- **Data readers** (`R/data_readers.R`): `read_own_data()` and `read_literature_data()` parse a data file into plain tidy tibbles for ad hoc analysis in a script — no rendering involved. Use these when comparing own data against a differently-formatted dataset (e.g. literature values with different, non-overlapping size bins), where the two datasets need different analysis operations rather than a shared report template.

## Development commands

```r
# Load package for development (does not make inst/ files findable via system.file)
devtools::load_all()

# Rebuild documentation from roxygen2 comments
devtools::document()
# or, if devtools is unavailable:
roxygen2::roxygenise()

# Install locally (required to test Rmd templates via system.file)
devtools::install_local(".")
# or, if devtools is unavailable:
install.packages(".", repos = NULL, type = "source")

# Check the package (runs R CMD CHECK)
devtools::check()
```

**Testing note:** `devtools::load_all()` does not make `inst/` files findable via `system.file()`. To test Rmd templates end-to-end, use a full local install. To iterate on an Rmd without reinstalling, call `rmarkdown::render()` directly on the template path.

## Architecture

The package has two layers:

1. **R functions** (`R/render_helpers.R`) — thin launchers that validate inputs, resolve the bundled Rmd template via `system.file()`, create an `outputs/` directory in the caller's working directory, and call `rmarkdown::render()` passing all user parameters as `params`. All analysis logic belongs in the Rmd templates, not here.

2. **Rmd templates** (`inst/rmd/`) — two templates:
   - `soil_profile_comparison.Rmd` — multi-file report; compares datasets across separate instrument export files, organised by depth. Colour dimension is `dataset`.
   - `pretreatment_comparison.Rmd` — single-file report; compares pretreatment methods encoded in `meta_code` within one file. Colour dimension is `meta_code`, mapped to full descriptions via `pretreatment_descriptions`. Colours are auto-assigned from a fixed palette and kept consistent across all plots.

Both templates filter to `"Average of '...'"` rows only before parsing, so only Mastersizer-averaged records are used (not individual measurement snapshots).

## Sample naming convention

```
<sample_id>_<meta_code>_<rep_number>_<optional_note>
```
- `sample_id` includes the depth value as a trailing number (e.g. `25-CR-R-0.4`)
- `meta_code` is a single uppercase letter identifying the pretreatment (see below)
- Samples sharing the same `sample_id` + `meta_code` within a dataset are treated as replicates
- Depth units must be consistent across all datasets (all metres or all centimetres)

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

The `pretreatment_descriptions` named vector in `pretreatment_comparison.Rmd` is the single source of truth for this mapping — update it there if codes change.

## Reading literature / differently-binned data

`read_literature_data()` parses bin edges directly from CSV column headers (e.g. `"<2 um"`, `"2-5 um"`, `"50 um - 2 mm"`), so header text can vary as long as each names a size range in µm or mm. It classifies a column as a **reported subtotal** (kept in `$samples` for cross-checking, excluded from `$bins`) whenever its range is a strict superset of another column's range — this is what distinguishes an independent, non-overlapping bin from a combined column like `"2-20 um"` that duplicates two finer bins. If a depth value looks like an Excel-mangled date (e.g. `"Sep-35"` from a typed range like `"9-35"` being auto-corrected), the function stops with an error rather than silently misreading it — fix the source file and re-read.

## Usage templates

- `inst/examples/generate_report_template.R` — multi-file soil profile comparison
- `inst/examples/pretreatment_report_template.R` — single-file pretreatment comparison
- `inst/examples/read_two_datasets_template.R` — read own + literature data as tidy tibbles for custom analysis

The report templates are intended to be copied to the user's analysis project and customised; reports are written to `outputs/` relative to the user's working directory. The data-reader template is a starting point for a custom analysis script — there's no fixed output shape since the whole point is to let you drive the analysis yourself.
