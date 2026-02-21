# Use the released version of daaprverse to create a
# canonical daap to test against. The daap will exist in the fixtures directory

# Run this in a terminal with RScript, because it will screw up your active renv
# and attached packages otherwise!
# By the end of this script the new daap's renv will be active, but you'll still be
# in the wd you started in.

# Require a GITHUB_PAT is set
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
  github_repo_url = "https://github.com/daapr-team/dp-test.git" # TODO does this need to be a valid repo?
)
# This makes the first 2 commits, "project init" and "dp init", but doesn't push them

# Now you're in the dp-test renv, but still in the wd where you started.
# Change directories to tmp dp project dir
daapr_dir <- getwd()
daapr_fixtures_dir <- file.path(daapr_dir, testthat::test_path("fixtures"))
dev_fixtures_deployed_dir <- file.path(daapr_fixtures_dir, deployed_dir_name)
dev_fixtures_daap_dir <- file.path(daapr_fixtures_dir, daap_dir_name)
setwd(temp_dp_project_dir) # TODO restart?

# TODO make sure we're using the "right" daaprverse versions

# Create default code
dpcode_add(project_path = ".")
# TODO: do we want to do this "fix" here? Maybe we should leave it as-is and this will give us a way
# to test that we've fixed the bug later
git2r::add(path=file.path(temp_dp_project_dir, "dp_journal.RMD"))
git2r::commit(message="Add dp_journal RMD")

# Add input files and derivation code
config <- dpconf_get(project_path = ".")

# copy input files to tmp dp dir
file.copy(file.path(daapr_fixtures_dir, "sdtm/dm.csv"),
          "input_files/")
file.copy(file.path(daapr_fixtures_dir, "sdtm/rs_onco_imwg.csv"),
          "input_files/")

input_map <- dpinput_map(project_path = ".")
input_map <- inputmap_clean(input_map = input_map)
synced_map <- dpinput_sync(conf = config, input_map = input_map)
dpinput_write(project_path = ".", input_d = synced_map)
git2r::add(path=file.path(temp_dp_project_dir, ".daap"))
git2r::commit(message="Add sdtm inputs")

# copy derivation files to tmp dp dir
file.copy(file.path(dev_fixtures_daap_dir, "R", "derive_subjects.R"),
          "R/")
file.copy(file.path(dev_fixtures_daap_dir, "R", "derive_bor.R"),
          "R/")
file.copy(file.path(dev_fixtures_daap_dir, "dp_make.R"),
          "dp_make.R", overwrite = TRUE)

# run dp_make script
targets::tar_make(script = "dp_make.R")
dp_commit(project_path = ".", commit_description = "First dp build")
# skip push step

dp_deploy(project_path = ".")
# Warning message: (coming from dpboardlog_update?)
# Use of .data in tidyselect expressions was deprecated in tidyselect 1.2.0.
# ℹ Please use `"dp_name"` instead of `.data$dp_name`
# Leslie: I don't get this error and I have tidyselect version 1.2.1


# Copy the test dp to the final location in fixtures and remove git artifacts

# NOTE: trying to use overwrite = TRUE for this fails with a permission error because the .rds files
# on the pin board are set to read only, so I had to delete the dir and re-copy it
# Actually, this is necessary anyway since the date-based dir names are going to change
# every time the test fixture is updated
if (dir.exists(dev_fixtures_deployed_dir)){
  unlink(dev_fixtures_deployed_dir, recursive = TRUE)
}
file.copy(file.path("..", deployed_dir_name), daapr_fixtures_dir, recursive = TRUE)

# Leslie: I think it's actually good to only copy over exactly what we want here
# less chance for accidental data/secrets committed that way
# TODO: Do we want to empty out the fixtures dir every time to prevent accidental file/data persistence?
if (!dir.exists(dev_fixtures_daap_dir)){dir.create(dev_fixtures_daap_dir)}
file.copy(".daap", dev_fixtures_daap_dir, recursive = TRUE, overwrite = TRUE)
file.copy(".gitignore", dev_fixtures_daap_dir, overwrite = TRUE)
file.copy(".renvignore", dev_fixtures_daap_dir, overwrite = TRUE)
file.copy("renv.lock", dev_fixtures_daap_dir, overwrite = TRUE)
file.copy("README.Rmd", dev_fixtures_daap_dir, overwrite = TRUE)
file.copy("dp_make.R", dev_fixtures_daap_dir, overwrite = TRUE)
file.copy(paste0(daap_dir_name, ".Rproj"), dev_fixtures_daap_dir, overwrite = TRUE)
file.copy("dp_journal.RMD", dev_fixtures_daap_dir, overwrite = TRUE) # TODO: update this when the file ext is fixed

# Leslie: I'm trying this circular setup of storing the derive functions in the dp-test
# fixture and also copying them from the fixture to the temp daap dir
# but maybe we don't need to include this step every time, since it's redundant
file.copy("R", dev_fixtures_daap_dir, recursive = TRUE, overwrite = TRUE)


# TODO other cleanup?
# TODO change back to daapr dir and exit renv?
# Leslie: I think we have to leave the wd and renv as-is, because we want to write
# tests from this point

# TODO make_local_test_daap function containing everything above except last copy step
# Note from Leslie: maybe we actually want 3 functions:
#     * make_local_test_daap: params, dp_init, and dpcode_add
#     * make_local_test_daap_inputs: copy sdtms, input_map, and dpinput_write
#     * deploy_local_test_daap: copy dp_make.R, tar_make(), and dp_deploy
