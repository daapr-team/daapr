# Get test ADaM or SDTM data from pharmaverse
library(readr)
install.packages("pharmaversesdtm")
library(pharmaversesdtm)

# write the dm and rs_onco_imwg datasets to sdtm directory within fixtures
sdtm_dir <- testthat::test_path("fixtures", "sdtm")
if (!dir.exists(sdtm_dir)) {
  dir.create(sdtm_dir, recursive = TRUE)
}

write_csv(dm, file.path(sdtm_dir, "dm.csv"))
write_csv(rs_onco_imwg, file.path(sdtm_dir, "rs_onco_imwg.csv"))
