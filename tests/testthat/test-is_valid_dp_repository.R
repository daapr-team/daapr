test_that("can be called without a path and checks the working directory", {
  not_a_dp <- withr::local_tempdir()
  withr::local_dir(not_a_dp)

  expect_false(is_valid_dp_repository())
})

test_that("default path gives the same result as the explicit path", {
  not_a_dp <- withr::local_tempdir()
  withr::local_dir(not_a_dp)

  expect_identical(
    is_valid_dp_repository(),
    is_valid_dp_repository(path = not_a_dp)
  )
})
