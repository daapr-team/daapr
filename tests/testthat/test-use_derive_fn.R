local_derive_fn_project <- function(valid = TRUE, .env = parent.frame()) {
  path <- withr::local_tempdir(.local_envir = .env)
  withr::local_dir(path, .local_envir = .env)
  local_mocked_bindings(is_valid_dp_repository = function(path) valid, .env = .env)
  if (requireNamespace("usethis", quietly = TRUE)) {
    local_mocked_bindings(
      edit_file = function(...) invisible(NULL),
      .package = "usethis",
      .env = .env
    )
  }
  path
}

test_that("errors outside a valid dp repository", {
  local_derive_fn_project(valid = FALSE)
  expect_error(use_derive_fn("ae"), "Not a dp repository")
  expect_false(dir.exists("R"))
})

test_that("checks repository before validating arguments", {
  local_derive_fn_project(valid = FALSE)
  expect_error(use_derive_fn(1), "Not a dp repository")
})

test_that("checks the repository at project_path", {
  local_derive_fn_project()
  checked <- NULL
  local_mocked_bindings(is_valid_dp_repository = function(path) {
    checked <<- path
    FALSE
  })
  expect_error(use_derive_fn("ae", project_path = "proj"), "dp_repository_check\\(\"proj\"\\)")
  expect_equal(checked, "proj")
})

test_that("creates the file under project_path", {
  local_derive_fn_project()
  dir.create("proj")
  expected <- file.path("proj", "R", "safety", "derive_ae_safety.R")
  out <- suppressMessages(use_derive_fn("ae", subdir = "safety", project_path = "proj"))
  expect_equal(out, expected)
  expect_true(file.exists(expected))
  expect_false(dir.exists("R"))
})

test_that("rejects invalid domain", {
  local_derive_fn_project()
  expect_error(use_derive_fn(1))
  expect_error(use_derive_fn(c("a", "b")))
  expect_error(use_derive_fn(""))
  expect_error(use_derive_fn(NULL))
  expect_error(use_derive_fn(NA_character_))
  expect_error(use_derive_fn("ae-x"), "valid R name")
  expect_error(use_derive_fn("ae x"), "valid R name")
  expect_false(dir.exists("R"))
})

test_that("accepts upper-case domain and subdir", {
  local_derive_fn_project()
  expected <- file.path(".", "R", "Safety", "derive_AE_Safety.R")
  out <- suppressMessages(use_derive_fn("AE", subdir = "Safety"))
  expect_equal(out, expected)
  expect_true(file.exists(expected))
})

test_that("rejects a domain that differs from an existing file only by case", {
  local_derive_fn_project()
  path <- suppressMessages(use_derive_fn("ae"))
  writeLines("existing", path)
  expect_error(use_derive_fn("AE"), "already exists")
  expect_error(use_derive_fn("Ae"), "already exists")
  expect_equal(readLines(path), "existing")
})

test_that("rejects a subdir that differs from an existing file only by case", {
  local_derive_fn_project()
  path <- suppressMessages(use_derive_fn("ae", subdir = "safety"))
  writeLines("existing", path)
  expect_error(use_derive_fn("ae", subdir = "Safety"), "already exists")
  expect_error(use_derive_fn("ae", subdir = "SAFETY"), "already exists")
  expect_equal(readLines(path), "existing")
})

test_that("reuses an existing subdirectory that differs only by case", {
  local_derive_fn_project()
  dir.create(file.path("R", "safety"), recursive = TRUE)
  out <- suppressMessages(use_derive_fn("ae", subdir = "Safety"))
  expect_equal(out, file.path(".", "R", "safety", "derive_ae_safety.R"))
  expect_true(file.exists(out))
  expect_equal(list.dirs("R", recursive = FALSE, full.names = FALSE), "safety")
})

test_that("prefers an exact subdirectory match over a case-insensitive one", {
  local_derive_fn_project()
  dir.create(file.path("R", "Safety"), recursive = TRUE)
  skip_if(dir.exists(file.path("R", "safety")), "file system is case-insensitive")
  dir.create(file.path("R", "safety"))
  out <- suppressMessages(use_derive_fn("ae", subdir = "safety"))
  expect_equal(out, file.path(".", "R", "safety", "derive_ae_safety.R"))
})

test_that("ignores non-R files when checking for conflicts", {
  local_derive_fn_project()
  dir.create("R")
  writeLines("derive_ae <- function(x) x", file.path("R", "notes.txt"))
  expect_no_error(suppressMessages(use_derive_fn("ae")))
})

test_that("rejects invalid subdir", {
  local_derive_fn_project()
  expect_error(use_derive_fn("ae", subdir = 1))
  expect_error(use_derive_fn("ae", subdir = c("a", "b")))
  expect_error(use_derive_fn("ae", subdir = ""))
  expect_error(use_derive_fn("ae", subdir = NA_character_))
  expect_error(use_derive_fn("ae", subdir = "../.."), "single folder name")
  expect_error(use_derive_fn("ae", subdir = ".."), "single folder name")
  expect_error(use_derive_fn("ae", subdir = "."), "single folder name")
  expect_error(use_derive_fn("ae", subdir = "a/b"), "single folder name")
  expect_error(use_derive_fn("ae", subdir = "safety-1"), "valid R name")
  expect_false(dir.exists("R"))
})

test_that("error messages don't evaluate braces in user input", {
  local_derive_fn_project()
  expect_error(use_derive_fn("ae", subdir = "{nope}"), "\\{nope\\}")
  expect_error(use_derive_fn("{1+1}"), "\\{1\\+1\\}")
  local_mocked_bindings(is_valid_dp_repository = function(path) FALSE)
  expect_error(use_derive_fn("ae", project_path = "{nope}"), "\\{nope\\}")
})

test_that("creates derive_<domain>.R in R/ when subdir is NULL", {
  local_derive_fn_project()
  expected <- file.path(".", "R", "derive_ae.R")
  expect_invisible(out <- suppressMessages(use_derive_fn("ae")))
  expect_equal(out, expected)
  expect_true(file.exists(expected))
})

test_that("creates derive_<domain>_<subdir>.R in R/<subdir>/", {
  local_derive_fn_project()
  expected <- file.path(".", "R", "safety", "derive_ae_safety.R")
  out <- suppressMessages(use_derive_fn("ae", subdir = "safety"))
  expect_equal(out, expected)
  expect_true(file.exists(expected))
})

test_that("reuses an existing subdirectory", {
  local_derive_fn_project()
  dir.create(file.path("R", "safety"), recursive = TRUE)
  expect_no_error(suppressMessages(use_derive_fn("ae", subdir = "safety")))
  expect_true(file.exists(file.path("R", "safety", "derive_ae_safety.R")))
})

test_that("generated file is valid R defining the derivation function", {
  local_derive_fn_project()
  path <- suppressMessages(use_derive_fn("ae"))
  env <- new.env()
  expect_no_error(sys.source(path, envir = env))
  expect_true(is.function(env$derive_ae))
  expect_equal(names(formals(env$derive_ae)), c("data_files_read", "config"))
})

test_that("generated file content matches template", {
  local_derive_fn_project()
  path <- suppressMessages(use_derive_fn("ae"))
  expect_snapshot(cat(readLines(path), sep = "\n"))
  path <- suppressMessages(use_derive_fn("ae", subdir = "safety"))
  expect_snapshot(cat(readLines(path), sep = "\n"))
})

test_that("reports the created file", {
  local_derive_fn_project()
  expect_message(use_derive_fn("ae"), "Created .*R/derive_ae\\.R")
})

test_that("errors and leaves file untouched when it already exists", {
  local_derive_fn_project()
  path <- suppressMessages(use_derive_fn("ae"))
  writeLines("existing", path)
  expect_error(use_derive_fn("ae"), "already exists")
  expect_equal(readLines(path), "existing")
})

test_that("errors when the same function file exists in another R/ folder", {
  local_derive_fn_project()
  existing <- suppressMessages(use_derive_fn("ae_safety"))
  expect_error(use_derive_fn("ae", subdir = "safety"), "already exists")
  expect_false(dir.exists(file.path("R", "safety")))
  expect_true(file.exists(existing))
})

test_that("errors when the function is already defined in another R/ file", {
  local_derive_fn_project()
  dir.create(file.path("R", "safety"), recursive = TRUE)
  writeLines("derive_ae <- function(x) x", file.path("R", "other.R"))
  writeLines("derive_ae_safety = function(x) x", file.path("R", "safety", "misc.R"))
  expect_error(use_derive_fn("ae"), "already exists in.*other\\.R")
  expect_error(use_derive_fn("ae", subdir = "safety"), "already exists in.*misc\\.R")
  expect_false(file.exists(file.path("R", "derive_ae.R")))
})

test_that("errors when the function is defined with different case in another R/ file", {
  local_derive_fn_project()
  dir.create("R")
  writeLines("derive_AE <- function(x) x", file.path("R", "other.R"))
  expect_error(use_derive_fn("ae"), "already exists in.*other\\.R")
  expect_false(file.exists(file.path("R", "derive_ae.R")))
})

test_that("ignores mentions of the function name that aren't definitions", {
  local_derive_fn_project()
  dir.create("R")
  writeLines(
    c("# derive_ae <- old version", "x <- derive_ae", "f <- function() derive_ae()"),
    file.path("R", "uses.R")
  )
  writeLines("derive_ae <- function(", file.path("R", "broken.R"))
  expect_no_error(suppressMessages(use_derive_fn("ae")))
})

test_that("opens the created file with usethis when available", {
  skip_if_not_installed("usethis")
  local_derive_fn_project()
  opened <- character()
  local_mocked_bindings(
    edit_file = function(path, ...) opened <<- c(opened, path),
    .package = "usethis"
  )
  path <- suppressMessages(use_derive_fn("ae"))
  expect_equal(opened, path)
})
