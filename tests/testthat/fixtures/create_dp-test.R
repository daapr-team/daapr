# Use the released version of daaprverse to create a
# canonical daap to test against. The daap will exist in the fixtures directory

# Run this in a terminal with RScript, because it will screw up your active renv
# and attached packages otherwise!
# By the end of this script the new daap's renv will be active, but you'll still be
# in the wd you started in.

options(renv.config.install.remotes=FALSE)
renv::remove(c("pinsLabkey", "dpi", "dpbuild", "dpdeploy", "daapr"))
# Don't use internal PPM for this as it's not publicly available
remotes::install_github("camorosi/pinsLabkey@main", upgrade="never")
remotes::install_github("amashadihossein/dpi@main", upgrade="never")
remotes::install_github("amashadihossein/dpbuild@main", upgrade="never")
remotes::install_github("amashadihossein/dpdeploy@main", upgrade="never")
remotes::install_github("amashadihossein/daapr@main", upgrade="never")

# Require a GITHUB_PAT is set
# Sys.setenv("GITHUB_PAT" = Sys.getenv("GITHUBdotCOM_PAT")) # TODO change envvar name
if (Sys.getenv("GITHUB_PAT") == ""){
  stop("You must set your GITHUB_PAT environment variable to proceed")
}

# TODO only include this step if we run into issues
# # Delete and re-create the dp-test repo so it's empty for dp_init
# gh::gh("DELETE /repos/{owner}/{repo}", owner="daapr-team", repo="dp-test")
# new_repo <- gh::gh("POST /orgs/{orgname}/repos", orgname="daapr-team", name="dp-test")

# Require daapr packages after migration to pins v1
package_version_check <- c(
  daapr = packageVersion("daapr"),
  dpi = packageVersion("dpi"),
  dpbuild = packageVersion("dpbuild"),
  dpdeploy = packageVersion("dpdeploy")
)
if (!all(package_version_check >= "0.1")){
  stop(glue::glue("The following packages have versions less than 0.1:
                  {glue::glue_collapse(names(package_version_check)[package_version_check < '0.1'], sep=', ')}"))
}

library(daapr)

dp_fixture_path <- testthat::test_path("fixtures", "dp-test")
dp_fixture_board <- testthat::test_path("fixtures", "dp-test_deployed")

# Initialize the new test daap within a temp dir
temp_dp_dir <- tempdir()
temp_dp_project_dir <- file.path(temp_dp_dir, "dp-test") # TODO create variables for these folder names
temp_dp_board_dir <- file.path(temp_dp_dir, "dp-test_deployed")

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
  github_repo_url = "https://github.com/daapr-team/dp-test2.git" # TODO does this need to be a valid repo?
)
# This makes the first 2 commits, "project init" and "dp init", but doesn't push them

# Now you're in the dp-test renv, but still in the wd where you started.
# Change directories to tmp dp project dir
daapr_dir <- getwd()
daapr_fixtures_dir <- file.path(daapr_dir, testthat::test_path("fixtures"))
setwd(temp_dp_project_dir) # TODO restart?
getwd()
.libPaths() # confirm that we've switched to dp-test renv
(package_version_check <- c(
  daapr = packageVersion("daapr"),
  pinsLabkey = packageVersion("pinsLabkey"),
  dpi = packageVersion("dpi"),
  dpbuild = packageVersion("dpbuild"),
  dpdeploy = packageVersion("dpdeploy")
))

# TODO make sure we're using the "right" daaprverse versions

# Create default code
dpcode_add(project_path = ".")
# This creates another local commit, "Added template code to dp project", but
# doesn't include dp_journal.RMD??? Commit this RMD separately.
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

# copy derivation files to tmp dp dir
file.copy(file.path(daapr_fixtures_dir, "derive_subjects.R"),
          "R/")
file.copy(file.path(daapr_fixtures_dir, "derive_bor.R"),
          "R/")
file.copy(file.path(daapr_fixtures_dir, "dp_make_test.R"),
          "dp_make.R", overwrite = T)

# run dp_make script
targets::tar_make(script = "dp_make.R")
dp_commit(project_path = ".", commit_description = "First dp build")
# skip push step

dp_deploy(project_path = ".")
# Warning message: (coming from dpboardlog_update?)
# Use of .data in tidyselect expressions was deprecated in tidyselect 1.2.0.
# ℹ Please use `"dp_name"` instead of `.data$dp_name`

# Copy the test dp to the final location in fixtures and remove git artifacts
file.copy("../dp-test_deployed/", file.path(daapr_fixtures_dir, "dp-test_deployed"), recursive = TRUE)
# TODO copy everything over and exclude below files
# to exclude: input and output files, R, renv/ tests/?
file.copy("./.daap/", file.path(daapr_fixtures_dir, "dp-test"), recursive = TRUE)
file.copy(".gitignore", file.path(daapr_fixtures_dir, "dp-test"))
file.copy(".renvignore", file.path(daapr_fixtures_dir, "dp-test"))
file.copy("renv.lock", file.path(daapr_fixtures_dir, "dp-test"))
file.copy("README.Rmd", file.path(daapr_fixtures_dir, "dp-test"))
file.copy("README.md", file.path(daapr_fixtures_dir, "dp-test"))

# unlink(file.path(dp_fixture_path, ".git"), recursive=TRUE)
# unlink(file.path(dp_fixture_path, "renv/library"), recursive=TRUE)

# TODO other cleanup?
# TODO change back to daapr dir and exit renv?

# TODO make_local_test_daap function containing everything above except last copy step

