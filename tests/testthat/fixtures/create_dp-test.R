# Use the released version of daaprverse to create a canonical daap to test against.
# The daap will exist in the fixtures directory.
# By the end of this script the new daap's renv will be active, but you'll still be
# in the wd you started in.

# Require a valid GITHUB_PAT is set
if (Sys.getenv("GITHUB_PAT") == ""){
  stop("You must set your GITHUB_PAT environment variable to proceed")
}

library(daapr)  # TODO: how could this work if we convert this to a function? roxygen import comment?

daap_dir_name <- "dp-test"
deployed_dir_name <- "dp-test_deployed"

dp_fixture_path <- testthat::test_path("fixtures", daap_dir_name)
dp_fixture_board <- testthat::test_path("fixtures", deployed_dir_name)

# Initialize the new test daap within a temp dir
temp_dp_dir <- tempdir()
temp_dp_project_dir <- file.path(temp_dp_dir, daap_dir_name)
temp_dp_board_dir <- file.path(temp_dp_dir, deployed_dir_name)

# folder can't be set as a variable here even though it's not a real secret
board_params_set_dried <- fn_dry(board_params_set_local(
  folder = "../dp-test_deployed"
))

# Initialize a new dp repo in temp directory
dp_repo <- dp_init(
  project_path = temp_dp_project_dir,
  project_description = "Example daap test fixture",
  branch_name = "main",
  branch_description = "Main",
  readme_general_note = "",
  board_params_set_dried = board_params_set_dried,
  github_repo_url = "https://github.com/daapr-team/dp-test.git"
)

# Now you're in the dp-test renv, but still in the wd where you started.
# Change directories to tmp dp project dir
daapr_dir <- getwd()
daapr_fixtures_dir <- file.path(daapr_dir, testthat::test_path("fixtures"))
dev_fixtures_deployed_dir <- file.path(daapr_fixtures_dir, deployed_dir_name)
dev_fixtures_daap_dir <- file.path(daapr_fixtures_dir, daap_dir_name)
setwd(temp_dp_project_dir)

# Create default code
dpcode_add(project_path = ".")

# Add input files and derivation code
config <- dpconf_get(project_path = ".")

# copy input files to tmp dp dir
fs::file_copy(file.path(daapr_fixtures_dir, "sdtm/dm.csv"),
              "input_files/")
fs::file_copy(file.path(daapr_fixtures_dir, "sdtm/rs_onco_imwg.csv"),
              "input_files/")

input_map <- dpinput_map(project_path = ".")
input_map <- inputmap_clean(input_map = input_map)
synced_map <- dpinput_sync(conf = config, input_map = input_map)
dpinput_write(project_path = ".", input_d = synced_map)

# copy derivation files to tmp dp dir
fs::file_copy(file.path(dev_fixtures_daap_dir, "R", "derive_subjects.R"),
              "R/")
fs::file_copy(file.path(dev_fixtures_daap_dir, "R", "derive_bor.R"),
              "R/")
fs::file_copy(file.path(dev_fixtures_daap_dir, "dp_make.R"),
              "dp_make.R", overwrite = TRUE)

# run dp_make script
targets::tar_make(script = "dp_make.R")
dp_commit(project_path = ".", commit_description = "First dp build")
# skip push step

deployed <- dp_deploy(project_path = ".")

# Copy the test dp to the final location in fixtures and remove git artifacts

# Wipe existing dp-test_deployed dir every time due to different pins version names
if (dir.exists(dev_fixtures_deployed_dir)){
  unlink(dev_fixtures_deployed_dir, recursive = TRUE)
}
fs::dir_copy(file.path("..", deployed_dir_name), daapr_fixtures_dir)

# Wipe existing dp-test dir and only copy over specific files desired
if (dir.exists(dev_fixtures_daap_dir)){
  unlink(dev_fixtures_daap_dir, recursive = TRUE)
}
dir.create(dev_fixtures_daap_dir)
fs::dir_copy(".daap", file.path(dev_fixtures_daap_dir, ".daap"), overwrite = TRUE)
fs::file_copy(".gitignore", dev_fixtures_daap_dir, overwrite = TRUE)
fs::file_copy(".renvignore", dev_fixtures_daap_dir, overwrite = TRUE)
fs::file_copy("renv.lock", dev_fixtures_daap_dir, overwrite = TRUE)
fs::file_copy("README.Rmd", dev_fixtures_daap_dir, overwrite = TRUE)
fs::file_copy("dp_make.R", dev_fixtures_daap_dir, overwrite = TRUE)
fs::file_copy("dp_journal.RMD", dev_fixtures_daap_dir, overwrite = TRUE) # TODO: update this when the file ext is fixed
fs::dir_copy("R", file.path(dev_fixtures_daap_dir, "R"), overwrite = TRUE)
# .Rproj is not created unless you're working interactively from RStudio
# fs::file_copy(paste0(daap_dir_name, "x.Rproj"), dev_fixtures_daap_dir, overwrite = TRUE)

if (interactive()){
  warning("Check your library paths and current working directory before proceeding!")
}
