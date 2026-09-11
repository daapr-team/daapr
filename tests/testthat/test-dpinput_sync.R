# Without the NA guard on the prefix, inputs sync to "NAdpinput/".
test_that("init_board.s3_board builds prefix correctly when prefix is absent", {
  local_mocked_board_s3()

  board <- init_board.s3_board(s3_test_conf(prefix = NULL))

  expect_equal(board$prefix, "dpinput/")
  expect_no_match(board$prefix, "NA")
})

test_that("init_board.s3_board builds prefix correctly when prefix is provided", {
  local_mocked_board_s3()

  board <- init_board.s3_board(s3_test_conf(prefix = "data-products/"))

  expect_equal(board$prefix, "data-products/dpinput/")
})
