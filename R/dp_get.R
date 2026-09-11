#' @title Get the data product from the remote pin board
#'
#' @description Get a data product object from the provided remote pin board,
#'   including input links and output data structure. By default get the latest
#'   version, or get a particular version by specifying the version hash (find
#'   available versions using `dp_list`).
#'
#' @param board_object A `pins_board` object from `dp_connect`.
#' @param data_name The name of the data product to get from the remote pin
#'   board, i.e. "dp-cars-us001". To get a list of data products available on
#'   the remote pin board, use `dp_list`.
#' @param version The hash specifying the data product version to get from the
#'   remote pin board. If `NULL`, `dp_get` will get the latest version
#'   available. To get a list of versions available for each data product on the
#'   remote pin board, use `dp_list`.
#'
#' @return A data product object, which is a list with class `dp` and items
#'   `input`, `output`, and `README`.
#'
#' @examples
#' \dontrun{
#' aws_creds <- creds_set_aws(
#'   key = Sys.getenv("AWS_KEY"),
#'   secret = Sys.getenv("AWS_SECRET")
#' )
#' board_params <- board_params_set_s3(
#'   bucket_name = "bucket_name",
#'   region = "us-east-1"
#' )
#' board_object <- dp_connect(board_params, aws_creds)
#' dp <- dp_get(board_object, data_name = "data-name")
#' }
#' @importFrom dplyr .data
#' @export
dp_get <- function(board_object, data_name, version = NULL) {
  # check for whether we're getting input or data product
  is_dpinput <- is_dpinput_board(board_object)

  # only check if pin name exists if it's not an input
  if (!is_dpinput) {
    dp_ls <- dp_list(board_object = board_object)
    available_datanames <- dp_ls |>
      dplyr::filter(!.data$archived) |>
      dplyr::pull(.data$dp_name)

    if (!data_name %in% available_datanames) {
      stop(cli::format_error(glue::glue(
        "data_name {data_name} is either archived",
        " or not on this board. Check the ",
        "data_name",
        " or cannot read from the board."
      )))
    }
  }

  # If we're trying to get a specific version, look up hash
  if (length(version) > 0) {
    pin_versions <- get_pin_versions(board_object, data_name)

    if (!version %in% (pin_versions$hash)) {
      stop(cli::format_error(glue::glue(
        "version {version} is not on this ",
        "board. Check the version."
      )))
    } else {
      specified_version <- version
      version <- pin_versions |>
        dplyr::filter(.data$hash == specified_version) |>
        dplyr::pull(version)
      # Check in case we've manage to pin the same hash more than once
      if (length(version) > 1) {
        version <- version[length(version)]
        message(paste0(
          "More than one pin version found with hash ",
          specified_version, ". Using latest version: ",
          version
        ))
      }
    }
  }

  # get pin, specifying version if provided
  dp <- read_pin_from_board(board_object, data_name, version)

  return(dp)
}

#' Read Pin from Board (internal)
#'
#' @description Internal wrapper function that reads a pin from a board object.
#'   Automatically selects the appropriate pin_read function based on the board
#'   type (LabKey vs. standard pins).
#'
#' @param board_object A `pins_board` object from `dp_connect`. Can be a
#'   folder board, LabKey board, or S3 board.
#' @param data_name The name of the data product to read.
#' @param version The version of the pin to read. If `NULL`, reads the latest
#'   version available.
#'
#' @return The data product object read from the pin board.
#'
#' @keywords internal
read_pin_from_board <- function(board_object, data_name, version = NULL) {
  if (board_object$board == "pins_board_labkey") {
    dp <- pinsLabkey::pin_read(
      name = data_name, board = board_object,
      version = version
    )
  } else {
    dp <- pins::pin_read(
      name = data_name, board = board_object,
      version = version
    )
  }

  return(dp)
}

#' Get Pin Versions from Board (internal)
#'
#' @description Internal wrapper function that retrieves pin versions from a
#'   board object. Automatically selects the appropriate pin_versions function
#'   based on the board type (LabKey vs. standard pins).
#'
#' @param board_object A `pins_board` object from `dp_connect`. Can be a
#'   folder board, LabKey board, or S3 board.
#' @param data_name The name of the data product to get versions for.
#'
#' @return A data frame containing version information with columns for hash,
#'   version, and other metadata depending on the board type.
#'
#' @keywords internal
get_pin_versions <- function(board_object, data_name) {
  if (board_object$board == "pins_board_labkey") {
    pin_versions <- pinsLabkey::pin_versions(
      board = board_object,
      name = data_name
    )
  } else {
    pin_versions <- pins::pin_versions(
      board = board_object,
      name = data_name
    )
  }

  return(pin_versions)
}

#' Check if Board References Data Product Input (internal)
#'
#' @description Internal helper function that determines whether a pins board
#'   object is configured to reference a data product input folder (dpinput)
#'   based on the board type and its path configuration.
#'
#' @param board_object A `pins_board` object from `dp_connect`. Can be a
#'   local board, LabKey board, or S3 board.
#'
#' @return Logical value: `TRUE` if the board references a data product input
#'   folder, `FALSE` if it references a regular data product folder.
#'
#' @details The function examines the board's path configuration:
#'   - For `pins_board_folder`: checks the `path` attribute
#'   - For `pins_board_labkey`: checks the `subdir` attribute
#'   - For `pins_board_s3` boards: checks the `prefix` attribute
#'
#'   It splits the path by underscores, hyphens, and slashes, then checks if
#'   the last component equals "dpinput".
#'
#' @keywords internal
is_dpinput_board <- function(board_object) {
  if (board_object$board == "pins_board_folder") {
    path_to_check <- board_object$path
  } else if (board_object$board == "pins_board_labkey") {
    path_to_check <- board_object$subdir
  } else { # s3 board
    path_to_check <- board_object$prefix
  }

  is_dpinput <- rev(unlist(strsplit(
    x = path_to_check,
    split = "_|-|/"
  )))[1] == "dpinput"

  return(is_dpinput)
}
