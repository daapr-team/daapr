#' Create a derivation function template
#'
#' Writes a template derivation function named `derive_<domain>_<subdir>` to
#' `<project_path>/R/<subdir>/`, or `derive_<domain>` to `<project_path>/R/`
#' when `subdir` is `NULL`.
#'
#' @param domain Name of the domain the derivation function reads from.
#' @param subdir Optional subdirectory of `R/` in which to create the function.
#'   An existing folder whose name differs only by case is reused, and its name
#'   is used in the function name.
#' @param project_path Path to the project folder (default is current directory)
#'
#' @return The path to the created file, invisibly.
#' @examples \dontrun{
#' # From the root of a dp project
#' use_derive_fn("ae")
#' use_derive_fn("ae", subdir = "safety")
#' }
#' @export
use_derive_fn <- function(domain, subdir = NULL, project_path = ".") {
  # Generated files are only sourced by a dp project's dp_make.R
  if (!is_valid_dp_repository(path = project_path)) {
    stop(cli::format_error(
      "Not a dp repository. Run `dp_repository_check(\"{project_path}\")` for details"
    ))
  }

  # domain and subdir must each be a single non-empty string (subdir may be NULL)
  is_string <- function(x) is.character(x) && length(x) == 1 && !is.na(x) && nzchar(x)
  if (!is_string(domain)) {
    stop(cli::format_error("`domain` must be a single non-empty string."))
  }
  if (!is.null(subdir) && !is_string(subdir)) {
    stop(cli::format_error("`subdir` must be NULL or a single non-empty string."))
  }

  # Keep files inside R/: "." and ".." pass the name check below but escape the folder
  if (!is.null(subdir) && (subdir %in% c(".", "..") || basename(subdir) != subdir)) {
    stop(cli::format_error(
      "`subdir` must be a single folder name within R/; got: {.val {subdir}}"
    ))
  }

  r_dir <- file.path(project_path, "R")
  subdir <- existing_subdir(r_dir, subdir)

  # A syntactically invalid function name would break sourcing of the whole R/ folder
  fn_name <- paste(c("derive", domain, subdir), collapse = "_")
  if (!identical(make.names(fn_name), fn_name)) {
    stop(cli::format_error(
      "`domain` and `subdir` must form a valid R name; got: {.val {fn_name}}"
    ))
  }
  dir_path <- do.call(file.path, as.list(c(r_dir, subdir)))
  file_path <- file.path(dir_path, glue::glue("{fn_name}.R"))

  conflicts <- derive_fn_conflicts(r_dir, fn_name)
  if (length(conflicts) > 0) {
    stop(cli::format_error("Function {.fn {fn_name}} already exists in: {.path {conflicts}}"))
  }

  # Custom delimiters avoid clashing with the braces in the generated function
  fn_text <- glue::glue(
    "
    <<fn_name>> <- function(data_files_read, config) {

      # This is just example code! Replace this with your actual derivation code.
      derived_<<domain>> <- data_files_read$<<domain>>(config = config) |>
        mutate(new_col = old_col + 5)

      return(derived_<<domain>>)
    }
    ",
    .open = "<<",
    .close = ">>"
  )

  dir.create(dir_path, showWarnings = FALSE, recursive = TRUE)
  writeLines(fn_text, file_path)
  cli::cli_alert_success("Created {.path {file_path}}")

  if (requireNamespace("usethis", quietly = TRUE)) {
    usethis::edit_file(file_path)
  }

  invisible(file_path)
}


#' @title Find an existing subdirectory matching a name, ignoring case
#' @description Case-insensitive file systems would put files for "Safety" in
#'   an existing "safety" folder, while case-sensitive ones would create a
#'   sibling, so reuse the existing folder's name on every platform.
#' @param r_dir path to the project's `R/` folder
#' @param subdir requested subdirectory name, or `NULL`
#' @return `subdir`, or the name of the existing folder that matches it
#' @noRd
existing_subdir <- function(r_dir, subdir) {
  if (is.null(subdir)) {
    return(NULL)
  }
  dirs <- list.dirs(r_dir, recursive = FALSE, full.names = FALSE)
  matches <- dirs[tolower(dirs) == tolower(subdir)]
  if (subdir %in% matches || length(matches) == 0) subdir else matches[[1]]
}


#' @title Find R/ files that clash with a derivation function
#' @description Files or functions in `R/` with the same name as `fn_name`,
#'   ignoring case, would clash when sourced.
#' @param r_dir path to the project's `R/` folder
#' @param fn_name name of the derivation function
#' @return paths of the `.R` files that conflict with `fn_name`
#' @noRd
derive_fn_conflicts <- function(r_dir, fn_name) {
  r_files <- list.files(r_dir, pattern = "\\.[rR]$", recursive = TRUE, full.names = TRUE)
  defines_fn <- function(path) {
    exprs <- tryCatch(parse(path, keep.source = FALSE), error = function(e) NULL)
    any(vapply(exprs, function(e) {
      is.call(e) && is.name(e[[1]]) && as.character(e[[1]]) %in% c("<-", "=", "<<-") &&
        is.name(e[[2]]) && tolower(as.character(e[[2]])) == tolower(fn_name)
    }, logical(1)))
  }
  same_file <- tolower(basename(r_files)) == tolower(glue::glue("{fn_name}.R"))
  same_fn <- vapply(r_files, defines_fn, logical(1))
  r_files[same_file | same_fn]
}
