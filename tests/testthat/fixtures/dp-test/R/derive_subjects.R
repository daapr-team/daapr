derive_subjects <- function(data_files_read, config) {
  # Extract relevant subject level info
  dm <- data_files_read$dm(config = config) |>
    distinct(USUBJID, RFXSTDTC, ACTARMCD) |>
    filter(!ACTARMCD == "Scrnfail")
}