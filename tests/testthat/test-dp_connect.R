# Prefix construction itself is unit-tested in test-s3_board_prefix.R. These
# tests only confirm the S3-specific wiring: that the constructed prefix reaches
# pins::board_s3(), and that an explicit board_subdir overrides the default.
test_that("dp_connect.s3_board passes the constructed prefix through to board_s3", {
  skip_if_not_installed("paws.storage")
  local_mocked_board_s3()

  board <- dp_connect(
    board_params = s3_test_board_params(prefix = "data-products/"),
    creds = s3_test_creds()
  )

  expect_equal(board$prefix, "data-products/daap/")
})

test_that("dp_connect.s3_board honours an explicit board_subdir", {
  skip_if_not_installed("paws.storage")
  local_mocked_board_s3()

  board_no_prefix <- dp_connect(
    board_params = s3_test_board_params(prefix = NULL),
    creds = s3_test_creds(), board_subdir = "dpinput/"
  )
  expect_equal(board_no_prefix$prefix, "dpinput/")

  board_with_prefix <- dp_connect(
    board_params = s3_test_board_params(prefix = "data-products/"),
    creds = s3_test_creds(), board_subdir = "dpinput/"
  )
  expect_equal(board_with_prefix$prefix, "data-products/dpinput/")
})
