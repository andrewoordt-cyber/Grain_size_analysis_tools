# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package overview

`grainSizeTools` is an R package that generates HTML reports comparing soil profile grain size data from laser particle size analyser (LPSA) instrument exports. The two exported functions are `generate_grain_size_report()` and `create_dataset()`, both defined in `R/render_helpers.R`.

## Development commands

```r
# Install dependencies and load package for development
devtools::install_deps()
devtools::load_all()

# Rebuild documentation from roxygen2 comments
devtools::document()

# Install the package locally
devtools::install_local(".")

# Check the package (runs R CMD CHECK)
devtools::check()
```

## Architecture

The package has two layers:

1. **R functions** (`R/render_helpers.R`) — `create_dataset()` builds a named list `(path, label, colour)`, and `generate_grain_size_report()` validates inputs, resolves the bundled Rmd template via `system.file()`, creates an `outputs/` directory in the caller's working directory, and calls `rmarkdown::render()` passing all user parameters as `params`.

2. **Rmd template** (`inst/rmd/soil_profile_comparison.Rmd`) — the report logic lives entirely here. On render it:
   - reads each instrument export (tab-delimited, UTF-16LE) and normalises bin column names across datasets
   - parses sample names following the `<sample_id>_<meta_code>_<rep_number>_<optional_note>` convention into `sample_info`, then builds `replicate_groups` (filtered by `min_replicates`)
   - produces three report sections: USDA soil texture triangle (ggtern), per-depth grain size distribution comparisons, and per-sample replicate plots with D10/D50/D90 CV% tables

When adding new visualisations or processing steps, all analysis code belongs in the Rmd template, not in the R functions.

## Sample naming convention

Instrument export sample names must follow:
```
<sample_id>_<meta_code>_<rep_number>_<optional_note>
```
- `sample_id` includes the depth value as a trailing number (e.g. `25-CR-R-0.4`)
- `meta_code` is a single uppercase letter (e.g. `B`)
- Samples sharing the same `sample_id` + `meta_code` within a dataset are treated as replicates

## Usage template

`inst/examples/generate_report_template.R` is the intended starting point for end users — copy it to an analysis project and fill in paths and labels. The report is written to `outputs/` relative to the user's working directory.
