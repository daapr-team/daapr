# Shared fixtures and mocks for the s3 board tests. `board_params_set_s3()`
# stores an absent prefix as NA_character_ rather than NULL, so every place that
# pastes a subdir onto the prefix has to NA-guard it first.

s3_test_creds <- function() {
  creds_set_aws(key = "test_key", secret = "test_secret")
}

s3_test_board_params <- function(prefix = NULL) {
  board_params_set_s3(
    bucket_name = "bucket_name", prefix = prefix, region = "us-east-1"
  )
}

# Minimal conf of the shape dpconf_get() returns, for the internal
# dp_deployCore.s3_board() and init_board.s3_board() methods.
s3_test_conf <- function(prefix = NULL) {
  conf <- list(
    board_params = s3_test_board_params(prefix = prefix),
    creds = s3_test_creds()
  )
  class(conf) <- c("s3_board", class(conf))
  conf
}

# Replace pins::board_s3() with a stub returning a board-shaped list, so no AWS
# call is made. Also records the prefix it was called with, for callers that
# can't reach the returned board object themselves.
local_mocked_board_s3 <- function(.env = parent.frame()) {
  recorded <- new.env(parent = emptyenv())
  local_mocked_bindings(
    board_s3 = function(prefix, bucket, ...) {
      recorded$prefix <- prefix
      structure(list(board = "pins_board_s3", prefix = prefix, bucket = bucket),
        class = c("pins_board_s3", "pins_board")
      )
    },
    .package = "pins",
    .env = .env
  )
  invisible(recorded)
}
