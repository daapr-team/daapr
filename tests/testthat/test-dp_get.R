#### dp_get tests

test_that("dp_get retrieves a mocked data product object correctly from s3 pin board", {
  # Mock s3 board object
  board_object <- list(board = "pins_board_s3", prefix = "daap/")
  data_name <- "dp-cars-us001"

  # Use local_mocked_bindings for mocking
  local_mocked_bindings(
    dp_list = function(...) {
      data.frame(dp_name = "dp-cars-us001", archived = FALSE)
    },
    read_pin_from_board = function(...) {
      daap_object <- list(input = "input_data", output = "output_data", README = "README content")
      class(daap_object) <- c("dp", class(daap_object))
      return(daap_object)
    }
  )

  # Call dp_get
  dp <- dp_get(board_object, data_name)

  # Verify results
  expect_s3_class(dp, "dp")
  expect_named(dp, c("README", "input", "output"), ignore.order = TRUE)
  expect_equal(dp$input, "input_data")
  expect_equal(dp$output, "output_data")
  expect_equal(dp$README, "README content")
})

test_that("dp_get retrieves a data product object correctly from local pin board", {
  # Mock local board object
  board_object <- list(board = "pins_board_folder", path = "local_folder/daap/")
  data_name <- "dp-cars-us001"


  # Use local_mocked_bindings for mocking
  local_mocked_bindings(
    dp_list = function(...) {
      data.frame(dp_name = "dp-cars-us001", archived = FALSE)
    },
    read_pin_from_board = function(...) {
      daap_object <- list(input = "input_data", output = "output_data", README = "README content")
      class(daap_object) <- c("dp", class(daap_object))
      return(daap_object)
    }
  )

  # Call dp_get
  dp <- dp_get(board_object, data_name)

  # Verify results
  expect_s3_class(dp, "dp")
  expect_named(dp, c("README", "input", "output"), ignore.order = TRUE)
  expect_equal(dp$input, "input_data")
  expect_equal(dp$output, "output_data")
  expect_equal(dp$README, "README content")
})

test_that("dp_get throws appropriate error for invalid input", {
  # Mock invalid board object
  board_object <- list(board = "pins_board_s3", prefix = "daap/")
  data_name <- "invalid-data-name"

  # Use local_mocked_bindings for mocking
  local_mocked_bindings(
    dp_list = function(board_object) {
      data.frame(dp_name = c("dp-cars-us001"), archived = c(FALSE))
    }
  )

  # Expect error when calling dp_get
  expect_error(dp_get(board_object, data_name), "data_name invalid-data-name is either archived or not on this board")
})

test_that("dp_get retrieves specific version when version parameter is provided", {
  # Mock s3 board object
  board_object <- list(board = "pins_board_s3", prefix = "daap/")
  data_name <- "dp-cars-us001"
  version_hash <- "abc123"

  # Mock functions
  local_mocked_bindings(
    dp_list = function(...) {
      data.frame(dp_name = "dp-cars-us001", archived = FALSE)
    },
    get_pin_versions = function(...) {
      data.frame(
        hash = c("abc123", "def456"),
        version = c("20231201T120000Z-abc12", "20231202T120000Z-def45")
      )
    },
    read_pin_from_board = function(board_object, data_name, version) {
      # Verify that the correct version is passed
      expect_equal(version, "20231201T120000Z-abc12")
      daap_object <- list(input = "versioned_input", output = "versioned_output", README = "README")
      class(daap_object) <- c("dp", class(daap_object))
      return(daap_object)
    }
  )

  # Call dp_get with specific version
  dp <- dp_get(board_object, data_name, version = version_hash)
  # Verify results
  expect_s3_class(dp, "dp")
  expect_equal(dp$input, "versioned_input")
})

test_that("dp_get throws error for invalid version hash", {
  # Mock s3 board object
  board_object <- list(board = "pins_board_s3", prefix = "daap/")
  data_name <- "dp-cars-us001"
  invalid_version <- "invalid123"

  local_mocked_bindings(
    dp_list = function(...) {
      data.frame(dp_name = "dp-cars-us001", archived = FALSE)
    },
    get_pin_versions = function(...) {
      data.frame(
        hash = c("abc123", "def456"),
        version = c("20231201T120000Z-abc12", "20231202T120000Z-def45")
      )
    }
  )

  # Expect error for invalid version
  expect_error(
    dp_get(board_object, data_name, version = invalid_version),
    "version invalid123 is not on this board"
  )
})

test_that("dp_get handles multiple pins with same hash by using latest version", {
  board_object <- list(board = "pins_board_s3", prefix = "daap/")
  data_name <- "dp-cars-us001"
  version_hash <- "abc123"

  local_mocked_bindings(
    dp_list = function(...) {
      data.frame(dp_name = "dp-cars-us001", archived = FALSE)
    },
    get_pin_versions = function(...) {
      data.frame(
        hash = c("abc123", "abc123", "def456"),
        version = c("20231201T120000Z-abc12", "20231202T120000Z-abc12", "20231203T120000Z-def45")
      )
    },
    read_pin_from_board = function(board_object, data_name, version) {
      # Should use the latest version with the same hash
      expect_equal(version, "20231202T120000Z-abc12")
      daap_object <- list(input = "latest_input", output = "latest_output", README = "README")
      class(daap_object) <- c("dp", class(daap_object))
      return(daap_object)
    }
  )

  # Expect message about multiple versions
  expect_message(
    dp <- dp_get(board_object, data_name, version = version_hash),
    "More than one pin version found with hash abc123. Using latest version: 20231202T120000Z-abc12"
  )

  expect_s3_class(dp, "dp")
})

test_that("dp_get works correctly with LabKey boards", {
  # Mock LabKey board object
  board_object <- list(board = "pins_board_labkey", subdir = "project/folder/daap")
  data_name <- "dp-cars-us001"

  local_mocked_bindings(
    dp_list = function(...) {
      data.frame(dp_name = "dp-cars-us001", archived = FALSE)
    },
    read_pin_from_board = function(...) {
      daap_object <- list(input = "labkey_input", output = "labkey_output", README = "LabKey README")
      class(daap_object) <- c("dp", class(daap_object))
      return(daap_object)
    }
  )

  # Call dp_get
  dp <- dp_get(board_object, data_name)

  # Verify results
  expect_s3_class(dp, "dp")
  expect_equal(dp$input, "labkey_input")
  expect_equal(dp$output, "labkey_output")
  expect_equal(dp$README, "LabKey README")
})

test_that("dp_get skips validation for dpinput boards", {
  # Mock dpinput board object
  board_object <- list(board = "pins_board_folder", path = "some/path/dpinput")
  data_name <- "any-data-name"

  # Mock read_pin_from_board but NOT dp_list (it should not be called)
  local_mocked_bindings(
    dp_list = function(...) {
      stop("dp_list should not be called for dpinput boards")
    },
    read_pin_from_board = function(...) {
      input_object <- list(input = "input_data", output = "input_output", README = "Input README")
      class(input_object) <- c("dp", class(input_object))
      return(input_object)
    }
  )

  # Call dp_get - should not error even though data_name might not exist in dp_list
  dp <- dp_get(board_object, data_name)

  # Verify results
  expect_s3_class(dp, "dp")
  expect_equal(dp$input, "input_data")
})

test_that("dp_get throws error for archived data product", {
  board_object <- list(board = "pins_board_s3", prefix = "daap/")
  data_name <- "dp-archived-data"

  local_mocked_bindings(
    dp_list = function(...) {
      data.frame(
        dp_name = c("dp-cars-us001", "dp-archived-data"),
        archived = c(FALSE, TRUE)
      )
    }
  )

  # Expect error for archived data product
  expect_error(
    dp_get(board_object, data_name),
    "data_name dp-archived-data is either archived or not on this board"
  )
})

#### is_dpinput_board tests

# Tests for is_dpinput_board helper function
test_that("is_dpinput_board correctly identifies input boards for folder boards", {
  # Test folder board with dpinput path
  board_object_input <- list(board = "pins_board_folder", path = "some/path/to/dpinput")
  expect_true(is_dpinput_board(board_object_input))

  # Test folder board with dpinput path (underscore separator)
  board_object_input_underscore <- list(board = "pins_board_folder", path = "some_path_to_dpinput")
  expect_true(is_dpinput_board(board_object_input_underscore))

  # Test folder board with dpinput path (hyphen separator)
  board_object_input_hyphen <- list(board = "pins_board_folder", path = "some-path-to-dpinput")
  expect_true(is_dpinput_board(board_object_input_hyphen))

  # Test folder board with regular data product path
  board_object_regular <- list(board = "pins_board_folder", path = "some/path/to/daap")
  expect_false(is_dpinput_board(board_object_regular))

  # Test folder board with empty path ending in dpinput
  board_object_simple <- list(board = "pins_board_folder", path = "dpinput")
  expect_true(is_dpinput_board(board_object_simple))

  # Test folder board where dpinput is not the last component
  board_object_middle <- list(board = "pins_board_folder", path = "some/dpinput/other/path")
  expect_false(is_dpinput_board(board_object_middle))
})

test_that("is_dpinput_board correctly identifies input boards for LabKey boards", {
  # Test LabKey board with dpinput subdir
  board_object_input <- list(board = "pins_board_labkey", subdir = "project/folder/dpinput")
  expect_true(is_dpinput_board(board_object_input))

  # Test LabKey board with dpinput subdir (mixed separators)
  board_object_input_mixed <- list(board = "pins_board_labkey", subdir = "project_folder-dpinput")
  expect_true(is_dpinput_board(board_object_input_mixed))

  # Test LabKey board with regular data product subdir
  board_object_regular <- list(board = "pins_board_labkey", subdir = "project/folder/daap")
  expect_false(is_dpinput_board(board_object_regular))

  # Test LabKey board with simple dpinput subdir
  board_object_simple <- list(board = "pins_board_labkey", subdir = "dpinput")
  expect_true(is_dpinput_board(board_object_simple))
})

test_that("is_dpinput_board correctly identifies input boards for S3 boards", {
  # Test S3 board with dpinput prefix
  board_object_input <- list(board = "pins_board_s3", prefix = "bucket/folder/dpinput")
  expect_true(is_dpinput_board(board_object_input))

  # Test S3 board with regular data product prefix
  board_object_regular <- list(board = "pins_board_s3", prefix = "bucket/folder/daap")
  expect_false(is_dpinput_board(board_object_regular))

  # Test S3 board with simple dpinput prefix
  board_object_simple <- list(board = "pins_board_s3", prefix = "dpinput")
  expect_true(is_dpinput_board(board_object_simple))

  # Test other S3 board types (fallback to else case)
  board_object_other <- list(board = "pins_board_s3_custom", prefix = "bucket/folder/dpinput")
  expect_true(is_dpinput_board(board_object_other))
})

test_that("is_dpinput_board handles edge cases correctly", {
  # Test with empty path components
  # board_object_empty <- list(board = "pins_board_folder", path = "")
  # expect_false(is_dpinput_board(board_object_empty))

  # Test with path that has dpinput as substring but not exact match
  board_object_substring <- list(board = "pins_board_folder", path = "some/path/dpinput_extra")
  expect_false(is_dpinput_board(board_object_substring))

  # Test case sensitivity
  board_object_case <- list(board = "pins_board_folder", path = "some/path/DPINPUT")
  expect_false(is_dpinput_board(board_object_case))
})
