derive_bor <- function(data_files_read, config) {
  # Determine BOR from response data
  bor <- data_files_read$rs_onco_imwg(config = config) |>
    filter(RSCAT == "IMWG") |>
    select(USUBJID, RSSTRESC, VISIT, RSDTC, RSDY) |>
    # TODO one missing day in RSDTC -- impute?
    filter(RSDY > 0) |>
    mutate(ordered_response = match(RSSTRESC, c("PD", "SD", "MR", "PR", "VGPR", "CR", "sCR"))) |>
    slice_max(ordered_response, by = "USUBJID") |>
    distinct(USUBJID, BOR = RSSTRESC)
}
