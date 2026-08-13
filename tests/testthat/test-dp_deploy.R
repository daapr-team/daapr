test_that("properly checks valid repository ", {
  local_mocked_bindings(is_valid_dp_repository = function(path) FALSE)
  expect_snapshot(error = TRUE, {
    path <- "."
    dp_deploy(project_path = path)
  })
})


test_that("object_read properly detects type", {
  # project_path <- withr::local_tempfile()
  # path <- file.path(project_path, "output_files/qs_format/")
  # dir.create(path, recursive = TRUE)
  # qs::qsave(structure(list(), class = "dp"), file = file.path(path, "data_object.qs"))
  # expect_equal(
  #   detect_type(project_path),
  #   "qs"
  # )

  project_path <- withr::local_tempfile()
  path <- file.path(project_path, "output_files/RDS_format/")
  dir.create(path, recursive = TRUE)
  saveRDS(structure(list(), class = "dp"), file = file.path(path, "data_object.RDS"))
  expect_equal(
    detect_type(project_path),
    "rds"
  )
})

s3_test_dp <- function() {
  structure(list(),
    class = "dp", dp_name = "dp-cars-us001",
    branch_description = "test description"
  )
}

# dp_deployCore.s3_board() writes the pin and updates the board log after
# building the board. Neither is relevant to how the prefix is constructed.
local_mocked_deploy_writes <- function(.env = parent.frame()) {
  local_mocked_bindings(
    pin_write = function(...) invisible(NULL),
    .package = "pins",
    .env = .env
  )
  local_mocked_bindings(
    dpboardlog_update = function(...) invisible(TRUE),
    .env = .env
  )
}

# Without the NA guard on the prefix, the pin is written to "NAdaap/".
# dp_deployCore.s3_board() returns TRUE rather than the board it builds, so the
# prefix is read back off the recorded pins::board_s3() call.
test_that("dp_deployCore.s3_board builds prefix correctly when prefix is absent", {
  mocked_board <- local_mocked_board_s3()
  local_mocked_deploy_writes()

  expect_true(
    dp_deployCore.s3_board(
      conf = s3_test_conf(prefix = NULL), project_path = ".", d = s3_test_dp(),
      dlog = NULL, git_info = NULL, type = "rds"
    )
  )

  expect_equal(mocked_board$prefix, "daap/")
  expect_no_match(mocked_board$prefix, "NA")
})

test_that("dp_deployCore.s3_board builds prefix correctly when prefix is provided", {
  mocked_board <- local_mocked_board_s3()
  local_mocked_deploy_writes()

  dp_deployCore.s3_board(
    conf = s3_test_conf(prefix = "data-products/"), project_path = ".",
    d = s3_test_dp(), dlog = NULL, git_info = NULL, type = "rds"
  )

  expect_equal(mocked_board$prefix, "data-products/daap/")
})
