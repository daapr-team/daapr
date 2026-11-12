test_that("default '.' resolves to the absolute working directory", {
  tmp <- withr::local_tempdir()
  withr::local_dir(tmp)

  resolved <- project_path_resolve()

  expect_s3_class(resolved, "fs_path")
  expect_true(fs::is_absolute_path(resolved))
  expect_equal(fs::path_real(resolved), fs::path_real(tmp))
})

test_that("relative paths resolve against the working directory at call time", {
  tmp <- withr::local_tempdir()
  fs::dir_create(fs::path(tmp, "my_dp"))
  withr::local_dir(tmp)

  resolved <- project_path_resolve("my_dp")

  expect_equal(fs::path_real(resolved), fs::path_real(fs::path(tmp, "my_dp")))
  expect_equal(basename(resolved), "my_dp")
})

test_that("basename of a resolved '.' is the folder name, not '.'", {
  tmp <- withr::local_tempdir()
  proj <- fs::dir_create(fs::path(tmp, "my_dp"))
  withr::local_dir(proj)

  expect_equal(basename(project_path_resolve(".")), "my_dp")
})

test_that("resolved path is unaffected by later working-directory changes", {
  tmp <- withr::local_tempdir()
  proj <- fs::dir_create(fs::path(tmp, "my_dp"))
  other <- fs::dir_create(fs::path(tmp, "elsewhere"))
  withr::local_dir(proj)

  resolved <- project_path_resolve(".")
  setwd(other)

  expect_equal(fs::path_real(resolved), fs::path_real(proj))
})

test_that("fs_path input is accepted", {
  tmp <- withr::local_tempdir()

  expect_no_error(project_path_resolve(fs::path(tmp)))
})

test_that("non-path inputs error", {
  expect_error(project_path_resolve(NULL), "single non-empty string")
  expect_error(project_path_resolve(NA_character_), "single non-empty string")
  expect_error(project_path_resolve(""), "single non-empty string")
  expect_error(project_path_resolve(c("a", "b")), "single non-empty string")
  expect_error(project_path_resolve(1), "single non-empty string")
  expect_error(project_path_resolve(character(0)), "single non-empty string")
})
