# Use the development version of combined daapr to create a
# canonical daap to test against. The daap will exist in the fixtures directory

# Run this in a terminal with RScript, because it will screw up your active renv
# and attached packages otherwise!
# By the end of this script the new daap's renv will be active, but you'll still be
# in the wd you started in.

# options(renv.config.install.remotes=FALSE)
# Remove older versions of daapr pacakges if they are installed 
remove.packages(c("dpi",  "dpbuild", "dpdeploy", "daapr"))
# # Don't use internal PPM for this as it's not publicly available
remotes::install_github("camorosi/pinsLabkey@main", upgrade="never")
remotes::install_github("daapr-team/daapr@leslem/test-fixtures", upgrade="never")

# Require a GITHUB_PAT is set
Sys.setenv("GITHUB_PAT" = Sys.getenv("GITHUBdotCOM_PAT"))
if (Sys.getenv("GITHUB_PAT") == ""){
  stop("You must set your GITHUB_PAT environment variable to proceed")
}

# # Delete and re-create the dp-test repo so it's empty for dp_init
# gh::gh("DELETE /repos/{owner}/{repo}", owner="daapr-team", repo="dp-test")
# new_repo <- gh::gh("POST /orgs/{orgname}/repos", orgname="daapr-team", name="dp-test")

# Require daapr packages after migration to pins v1
package_version_check <- c(
  daapr = packageVersion("daapr")
)
if (!all(package_version_check >= "0.2")){
  stop(glue::glue("The following packages have versions less than 0.1:
                  {glue::glue_collapse(names(package_version_check)[package_version_check < '0.1'], sep=', ')}"))
}

library(daapr)

dp_fixture_path <- testthat::test_path("fixtures", "dp-test")
dp_fixture_board <- testthat::test_path("fixtures", "dp-test_deployed")

# Initialize the new test daap within a temp dir
temp_dp_dir <- tempdir()
temp_dp_project_dir <- file.path(temp_dp_dir, "dp-test")

# folder can't be set as a variable here even though it's not a real secret
board_params_set_dried <- fn_dry(board_params_set_local(
  folder = "tests/testthat/fixtures/dp-test_deployed"
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
# This makes the first 2 commits, "project init" and "dp init", but doesn't push them

# Now you're in the dp-test renv, but still in the wd where you started.
# You likely had an error from renv about a failure to install daapr from the
# public PPM. Install it now and snapshot.
# Note: it seems to have the correct combined version of daapr, so proceeding without the reinstall step
getwd()
.libPaths()
(package_version_check <- c(
  daapr = packageVersion("daapr"),
  pinsLabkey = packageVersion("pinsLabkey")
  # dpi = packageVersion("dpi"),
  # dpbuild = packageVersion("dpbuild"),
  # dpdeploy = packageVersion("dpdeploy")
))

# # allow installing any dependencies from source (git2r)
# options("install.packages.compile.from.source" = "yes")
# renv::install("remotes", prompt=FALSE)
# # renv::install("httr2", prompt=FALSE)
# remotes::install_github("daapr-team/daapr@dev", upgrade="never")
# renv::remove("remotes")
# renv::snapshot(prompt=FALSE)
# # Only public PPM is in the renv.lock repositories list, but these packages are
# # all either installed from RSPM (majority) or CRAN (1)???

# Create default code
dpcode_add(project_path = temp_dp_project_dir)
# This creates another local commit, "Added template code to dp project"
# if you have the latest version there shouldn't be an issue with uncommited files

# Add input files and derivation code
config <- dpconf_get(project_path = temp_dp_project_dir)

file.copy(testthat::test_path("fixtures", "sdtm/dm.csv"),
          file.path(temp_dp_project_dir, "input_files"))
file.copy(testthat::test_path("fixtures", "sdtm/rs_onco_imwg.csv"),
          file.path(temp_dp_project_dir, "input_files"))

input_map <- dpinput_map(project_path = temp_dp_project_dir)
input_map <- inputmap_clean(input_map = input_map)
synced_map <- dpinput_sync(conf = config, input_map = input_map) # board_params_set_local(folder = "tests/testthat/fixtures/dp-test_deployed")
dpinput_write(project_path = temp_dp_project_dir, input_d = synced_map)
# input_yaml_file <- file.path(temp_dp_project_dir, ".daap/daap_input.yaml")
# data_files_read <- dpinput_read(daap_input_yaml = yaml::read_yaml(file = input_yaml_file))

file.copy(testthat::test_path("fixtures", "derive_subjects.R"),
          file.path(temp_dp_project_dir, "R"))
file.copy(testthat::test_path("fixtures", "derive_bor.R"),
          file.path(temp_dp_project_dir, "R"))
file.copy(testthat::test_path("fixtures", "dp_make_test.R"),
          file.path(temp_dp_project_dir, "dp_make.R"), overwrite = T)

# Setting an env var here so I don't have to cd
Sys.setenv(TEMP_DP_PROJECT_DIR = temp_dp_project_dir)
targets::tar_make(script = file.path(temp_dp_project_dir, "dp_make.R"),
                  store = file.path(temp_dp_project_dir, "_targets")) # TODO this should store in temp dir
dp_commit(project_path = temp_dp_project_dir, commit_description = "First dp build")
# skip push step
library(lifecycle) # TODO had to load this; are dependencies not managed correctly?
dp_deploy(project_path = temp_dp_project_dir)
# Warning message: (coming from dpboardlog_update?)
# Use of .data in tidyselect expressions was deprecated in tidyselect 1.2.0.
# ℹ Please use `"dp_name"` instead of `.data$dp_name`

# Copy the test dp to the final location in fixtures and remove git artifacts
file.copy(temp_dp_project_dir, dirname(dp_fixture_path), recursive=TRUE)
unlink(file.path(dp_fixture_path, ".git"), recursive=TRUE)
unlink(file.path(dp_fixture_path, "renv/library"), recursive=TRUE)
unlink(file.path(dp_fixture_path, "_targets"), recursive=TRUE)

# restart R to exit the temporary renv

