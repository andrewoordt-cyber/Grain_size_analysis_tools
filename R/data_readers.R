#' Read an instrument export file (own LPSA data)
#'
#' Parses a tab-delimited Mastersizer export, keeping only the
#' `"Average of '...'"` rows, and splits it into per-bin particle size
#' distribution data and per-sample summary statistics. Sample names are
#' parsed according to the package's naming convention
#' (`<sample_id>_<meta_code>_<rep_number>_<optional_note>`, see `CLAUDE.md`).
#'
#' @param path Character. Path to the tab-delimited instrument export file.
#'
#' @return A list with two tibbles:
#' \describe{
#'   \item{psd}{Long-format: one row per sample per grain-size bin.
#'     Columns: `sample_name`, `sample_id`, `depth_val`, `meta_code`,
#'     `rep_num`, `note`, `grain_um`, `perc_vol_in`.}
#'   \item{summary}{Long-format: one row per sample per summary metric
#'     (e.g. `dx_10`, `dx_50`, `dx_90`). Columns: `sample_name`,
#'     `sample_id`, `depth_val`, `meta_code`, `note`, `metric`, `value_raw`.}
#' }
#' @export
#'
#' @examples
#' \dontrun{
#' own <- read_own_data("data/run1.txt")
#' own$psd
#' own$summary
#' }
read_own_data <- function(path) {

  if (missing(path) || !nzchar(path)) {
    stop("path is required.")
  }
  if (!file.exists(path)) {
    stop(paste("File not found:", path))
  }

  dat <- readr::read_delim(
    file           = path,
    delim          = "\t",
    locale         = readr::locale(encoding = "UTF-16LE"),
    show_col_types = FALSE
  ) |>
    dplyr::mutate(dplyr::across(
      dplyr::where(is.character),
      ~ gsub("\\?m", "um", .x)
    )) |>
    janitor::clean_names(replace = c("µ" = "u", "μ" = "u")) |>
    dplyr::filter(stringr::str_detect(sample_name, "^Average of\\s*'")) |>
    dplyr::mutate(
      sample_name = sample_name |>
        stringr::str_remove("^Average of\\s*'") |>
        stringr::str_remove("'\\s*$")
    )

  is_bin_col <- stringr::str_detect(names(dat), "^x\\d")

  psd_long <- dat[, c("sample_name", names(dat)[is_bin_col]), drop = FALSE] |>
    tidyr::pivot_longer(
      cols      = dplyr::matches("^x\\d"),
      names_to  = "grain_um",
      values_to = "perc_vol_in"
    ) |>
    dplyr::mutate(
      grain_um = as.numeric(
        stringr::str_replace_all(stringr::str_remove(grain_um, "^x"), "_", "."))
    )

  summ_long <- dat |>
    dplyr::select(-dplyr::matches("^x\\d")) |>
    tidyr::pivot_longer(
      cols      = dplyr::where(is.numeric),
      names_to  = "metric",
      values_to = "value_raw"
    )

  parse_sample_name <- function(nm) {
    tibble::tibble(sample_name = nm) |>
      dplyr::mutate(
        note      = stringr::str_extract(sample_name, "(?<=_\\d{1,3}_)[^_].+$"),
        rep_num   = stringr::str_extract(sample_name, "\\d+(?=(_[^_]+)?$)"),
        meta_code = stringr::str_extract(
          sample_name, paste0("(?<=_)[A-Z](?=_", rep_num, ")")
        ),
        sample_id = stringr::str_remove(
          sample_name,
          paste0("_", tidyr::replace_na(meta_code, ""),
                 dplyr::if_else(!is.na(meta_code), "_", ""),
                 rep_num,
                 dplyr::if_else(!is.na(note), paste0("_", note), ""),
                 "$")
        ),
        depth_val = as.numeric(stringr::str_extract(sample_id, "[\\d.]+$"))
      )
  }

  sample_info <- psd_long |>
    dplyr::distinct(sample_name) |>
    dplyr::bind_cols(
      parse_sample_name(
        psd_long |> dplyr::distinct(sample_name) |> dplyr::pull(sample_name)
      ) |> dplyr::select(-sample_name)
    )

  psd_long <- psd_long |>
    dplyr::left_join(
      sample_info |>
        dplyr::select(sample_name, sample_id, depth_val, meta_code, rep_num, note),
      by = "sample_name"
    )

  summ_long <- summ_long |>
    dplyr::left_join(
      sample_info |> dplyr::select(sample_name, sample_id, depth_val, meta_code, note),
      by = "sample_name"
    )

  list(psd = psd_long, summary = summ_long)
}

#' Read a literature-format grain size dataset
#'
#' Parses a literature dataset (comma- or tab-delimited — detected
#' automatically from the header line) reporting non-overlapping
#' percentage bins (e.g. clay / fine silt / coarse silt / fine sand / sand)
#' rather than the ~100 continuous log-spaced bins a Mastersizer produces.
#' Bin edges are parsed directly from the column headers (e.g. `"<2 um"`,
#' `"2-5 um"`, `"50 um - 2 mm"`), so headers may vary as long as each names a
#' size range in micrometres or millimetres. Any column whose range is a
#' superset of another column's range is treated as a reported subtotal
#' (e.g. a combined `"2-20 um"` column spanning two finer bins) and is kept
#' for cross-checking in `$samples`, but excluded from `$bins` since it is
#' not an independent bin and would double-count if summed with the rest.
#'
#' Depth is expected as a `"low-high"` range (e.g. `"9-35"`) or `"-"` for
#' unreported. If a depth value looks like an Excel-mangled date (e.g.
#' `"Sep-35"`, from Excel auto-correcting a typed range like `"9-35"`), the
#' function stops with an error rather than silently reading the wrong
#' value — fix the source file and re-read.
#'
#' @param path Character. Path to the literature data file (`.csv` or
#'   `.txt`; delimiter is auto-detected). Expected columns:
#'   a sample identifier (first column), a depth column (name starting with
#'   `"Depth"`), and one column per grain-size bin.
#' @param source Character. Label identifying which file/dataset a row came
#'   from, added as a `source` column on both returned tibbles — useful once
#'   you combine several literature files and need to tell same-named
#'   samples apart. Defaults to the file's basename (without extension) if
#'   not supplied.
#'
#' @return A list with two tibbles:
#' \describe{
#'   \item{bins}{Long-format: one row per sample per independent bin.
#'     Columns: `source`, `sample_id`, `depth_label`, `depth_low`,
#'     `depth_high`, `depth_mid`, `bin_label`, `bin_low_um`, `bin_high_um`,
#'     `pct`.}
#'   \item{samples}{One row per sample: `source`, `sample_id`,
#'     `depth_label`, `depth_low`, `depth_high`, `depth_mid`, plus any
#'     reported subtotal columns found in the file (prefixed `reported_`),
#'     for cross-checking against `bins`.}
#' }
#' @export
#'
#' @examples
#' \dontrun{
#' lit <- read_literature_data("data/literature_table.csv")
#' lit$bins
#' lit$samples
#' }
read_literature_data <- function(path, source = NULL) {

  if (missing(path) || !nzchar(path)) {
    stop("path is required.")
  }
  if (!file.exists(path)) {
    stop(paste("File not found:", path))
  }
  if (is.null(source)) {
    source <- tools::file_path_sans_ext(basename(path))
  }

  # Detect delimiter from the header line rather than assuming a comma —
  # literature exports are just as often tab-delimited .txt as comma .csv.
  first_line <- readLines(path, n = 1, warn = FALSE)
  delim <- if (stringr::str_count(first_line, "\t") >= stringr::str_count(first_line, ",")) {
    "\t"
  } else {
    ","
  }
  dat <- readr::read_delim(path, delim = delim, show_col_types = FALSE)

  raw_names  <- names(dat)
  sample_col <- raw_names[1]
  depth_col  <- grep("^depth", raw_names, ignore.case = TRUE, value = TRUE)[1]
  if (is.na(depth_col)) {
    stop("No depth column found (expected a column starting with 'Depth').")
  }
  bin_cols <- setdiff(raw_names, c(sample_col, depth_col))

  sample_id   <- dat[[sample_col]]
  depth_label <- as.character(dat[[depth_col]])

  month_like <- stringr::str_detect(
    depth_label,
    "^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d+$"
  )
  if (any(month_like, na.rm = TRUE)) {
    stop(
      "Depth column contains values that look like Excel-mangled date ",
      "ranges (e.g. 'Sep-35' instead of '9-35') for sample(s): ",
      paste(sample_id[which(month_like)], collapse = ", "),
      ". Fix these in the source file before reading."
    )
  }

  depth_low  <- suppressWarnings(as.numeric(stringr::str_extract(depth_label, "^\\d+(?=-)")))
  depth_high <- suppressWarnings(as.numeric(stringr::str_extract(depth_label, "(?<=-)\\d+$")))
  depth_mid  <- (depth_low + depth_high) / 2

  # Parse a bin header like "<2 um", "2-5 um", ">20 um", "50 um - 2 mm" into
  # a low/high edge pair in micrometres.
  to_um <- function(num, unit) {
    if (is.na(unit) || unit == "") unit <- "um"
    if (unit == "mm") num * 1000 else num
  }
  parse_bin_edges <- function(header) {
    h <- gsub("\\s+", "", header)
    if (grepl("^<", h)) {
      m <- regmatches(h, regexec("^<(\\d+\\.?\\d*)(um|mm)?", h))[[1]]
      return(c(low = 0, high = to_um(as.numeric(m[2]), m[3])))
    }
    if (grepl("^>", h)) {
      m <- regmatches(h, regexec("^>(\\d+\\.?\\d*)(um|mm)?", h))[[1]]
      return(c(low = to_um(as.numeric(m[2]), m[3]), high = Inf))
    }
    m <- regmatches(
      h, regexec("^(\\d+\\.?\\d*)(um|mm)?-(\\d+\\.?\\d*)(um|mm)?$", h)
    )[[1]]
    if (length(m) == 0) {
      stop("Could not parse bin edges from column header: ", header)
    }
    c(low = to_um(as.numeric(m[2]), m[3]), high = to_um(as.numeric(m[4]), m[5]))
  }

  edges <- lapply(bin_cols, parse_bin_edges)
  names(edges) <- bin_cols

  # A column is a reported subtotal if its range strictly contains another
  # bin column's range (i.e. it is the union of finer bins reported
  # elsewhere in the file), rather than an independent, non-overlapping bin.
  is_subtotal <- vapply(bin_cols, function(nm) {
    this   <- edges[[nm]]
    others <- edges[setdiff(bin_cols, nm)]
    any(vapply(others, function(o) {
      o[["low"]] >= this[["low"]] && o[["high"]] <= this[["high"]] &&
        !(o[["low"]] == this[["low"]] && o[["high"]] == this[["high"]])
    }, logical(1)))
  }, logical(1))

  independent_cols <- bin_cols[!is_subtotal]
  subtotal_cols     <- bin_cols[is_subtotal]

  bins <- purrr::map_dfr(independent_cols, function(nm) {
    e <- edges[[nm]]
    tibble::tibble(
      sample_id   = sample_id,
      depth_label = depth_label,
      depth_low   = depth_low,
      depth_high  = depth_high,
      depth_mid   = depth_mid,
      bin_label   = nm,
      bin_low_um  = unname(e[["low"]]),
      bin_high_um = unname(e[["high"]]),
      pct         = dat[[nm]]
    )
  })

  samples <- tibble::tibble(
    sample_id   = sample_id,
    depth_label = depth_label,
    depth_low   = depth_low,
    depth_high  = depth_high,
    depth_mid   = depth_mid
  )
  for (nm in subtotal_cols) {
    samples[[paste0("reported_", janitor::make_clean_names(nm))]] <- dat[[nm]]
  }

  bins    <- dplyr::mutate(bins,    source = source, .before = 1)
  samples <- dplyr::mutate(samples, source = source, .before = 1)

  list(bins = bins, samples = samples)
}
