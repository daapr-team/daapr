# s3_board_prefix() is the single source of truth for how dp_connect.s3_board()
# and dp_deployCore.s3_board() build their board prefix. It is pure string logic,
# so these tests need no paws.storage, no pins mocking, and never skip.

test_that("s3_board_prefix collapses an absent (NA) prefix to the subdir", {
  expect_equal(s3_board_prefix(NA_character_), "daap/")
  # Regression: without the NA guard the prefix becomes the literal "NAdaap/".
  expect_no_match(s3_board_prefix(NA_character_), "NA")
})

test_that("s3_board_prefix prepends a provided prefix", {
  expect_equal(s3_board_prefix("data-products/"), "data-products/daap/")
})

test_that("s3_board_prefix honours a custom subdir", {
  expect_equal(s3_board_prefix(NA_character_, "dpinput/"), "dpinput/")
  expect_equal(s3_board_prefix("data-products/", "dpinput/"), "data-products/dpinput/")
})
