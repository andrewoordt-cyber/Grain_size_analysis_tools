# read_two_datasets_template.R
# Copy this file to your analysis project and customise the paths below.
#
# Use this when you need to compare your own LPSA data against a
# differently-binned dataset (e.g. literature values) and want plain tidy
# tibbles to work with directly, rather than a rendered HTML report.
#
# Install the package once:
#   devtools::install_local("C:/Users/andre/Documents/R/Grain_size_analysis_tools")

library(grainSizeTools)
library(dplyr)
library(purrr)
library(ggplot2)

# ── Own data ──────────────────────────────────────────────────────────────
# Tab-delimited Mastersizer exports, "Average of '...'" rows only.
# List one or more files; read_own_data() takes one file per call, so
# multiple files are read and stacked with purrr::map_dfr().
own_files <- c(
  "data/your_file_1.txt"
  # , "data/your_file_2.txt"
)

own_results <- map(own_files, read_own_data)
own_psd     <- map_dfr(own_results, "psd")      # sample_name, sample_id, depth_val, meta_code, rep_num, note, grain_um, perc_vol_in
own_summary <- map_dfr(own_results, "summary")  # sample_name, sample_id, depth_val, meta_code, note, metric, value_raw (Dx_10/50/90 etc.)

# ── Literature data ───────────────────────────────────────────────────────
# CSV(s) with non-overlapping percentage bins, headers giving bin edges in
# um/mm (e.g. "<2 um", "2-5 um", "50 um - 2 mm"). Any reported subtotal
# columns (e.g. a combined "2-20 um" column) are kept in $samples for
# cross-checking but excluded from $bins.
#
# Each file gets a `source` column (defaults to the filename, or pass
# `source = "..."` per file for a custom label) so rows stay traceable once
# multiple literature files are combined — useful since sample IDs across
# unrelated literature sources aren't guaranteed to be unique.
lit_files <- c(
  "data/literature_table_1.csv"
  # , "data/literature_table_2.csv"
)
# Optional custom labels, same length/order as lit_files. Leave NULL to use
# each file's basename instead.
lit_sources <- NULL  # e.g. c("Smith 2019", "Jones 2021")

lit_results <- if (is.null(lit_sources)) {
  map(lit_files, read_literature_data)
} else {
  map2(lit_files, lit_sources, read_literature_data)
}
lit_bins    <- map_dfr(lit_results, "bins")     # source, sample_id, depth_label, depth_low, depth_high, depth_mid, bin_label, bin_low_um, bin_high_um, pct
lit_samples <- map_dfr(lit_results, "samples")  # source, sample_id, depth_label, depth_low, depth_high, depth_mid, plus any reported_* subtotal columns

# From here, analyse each dataset however makes sense for its own format —
# e.g. full log-scale PSD curves for own_psd, bar charts of bin % for
# lit_bins — and combine them only where a common quantity exists (e.g.
# clay/silt/sand %, which can be derived from either).
