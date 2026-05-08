test_that("dp_get reads the local test fixture daap", {
  fixture_board_params <- board_params_set_local(folder = testthat::test_path("fixtures", deployed_dir_name))
  fixture_board <- dp_connect(board_params = fixture_board_params)
  expect_s3_class(fixture_board, "pins_board_folder")
  listed_daaps <- dp_list(fixture_board)
  expect_equal(nrow(listed_daaps), 1)
  dp <- dp_get(fixture_board, data_name = listed_daaps$dp_name[1])
  expect_setequal(names(dp), c("README", "input", "output"))
  expect_setequal(names(dp$output), c("subjects", "bor"))
  purrr::walk(names(dp$output), .f=function(x){
    expect_s3_class(dp$output[[x]], "data.frame")
  })
  expect_setequal(names(dp$input), tools::file_path_sans_ext(list.files(testthat::test_path("fixtures/sdtm"))))
  # Currently fails due to known incompatibility with daaprverse inputs
  dm <- dp$input$dm(board_params = fixture_board_params)
  expect_s3_class(dm, "data.frame")
})
