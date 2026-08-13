# Without the NA guard on the prefix, these tests see a literal "NA" pasted into
# the board prefix.
test_that("dp_connect.s3_board builds prefix correctly when prefix is absent", {
  skip_if_not_installed("paws.storage")
  local_mocked_board_s3()

  board <- dp_connect(
    board_params = s3_test_board_params(prefix = NULL), creds = s3_test_creds()
  )

  expect_equal(board$prefix, "daap/")
  expect_no_match(board$prefix, "NA")
})

test_that("dp_connect.s3_board builds prefix correctly when prefix is provided", {
  skip_if_not_installed("paws.storage")
  local_mocked_board_s3()

  board <- dp_connect(
    board_params = s3_test_board_params(prefix = "data-products/"),
    creds = s3_test_creds()
  )

  expect_equal(board$prefix, "data-products/daap/")
})

test_that("dp_connect.s3_board NA-guards the prefix for an explicit board_subdir", {
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
