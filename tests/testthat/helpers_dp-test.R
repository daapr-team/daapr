# Define constants
daap_dir_name <- "dp-test"
deployed_dir_name <- "dp-test_deployed"

# Initialize a local test daap in a tempdir
init_local_test_daap <- function(){
  # Require a valid GITHUB_PAT is set
  if (Sys.getenv("GITHUB_PAT") == ""){
    stop("You must set your GITHUB_PAT environment variable to proceed")
  }
  
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
  withr::local_options(list(renv.verbose = FALSE))
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

  return(list(
    temp_dp_project_dir = temp_dp_project_dir,
    temp_dp_board_dir = temp_dp_board_dir,
    dev_fixtures_deployed_dir = dev_fixtures_deployed_dir,
    daapr_fixtures_dir = daapr_fixtures_dir,
    dev_fixtures_daap_dir = dev_fixtures_daap_dir
  ))
}

add_test_daap_inputs <- function(daapr_fixtures_dir) {
  # copy input files to tmp dp dir
  fs::file_copy(file.path(daapr_fixtures_dir, "sdtm/dm.csv"),
                "input_files/")
  fs::file_copy(file.path(daapr_fixtures_dir, "sdtm/rs_onco_imwg.csv"),
                "input_files/")
  
  # Add input files and derivation code
  config <- dpconf_get(project_path = ".")

  input_map <- dpinput_map(project_path = ".")
  input_map <- inputmap_clean(input_map = input_map)
  synced_map <- dpinput_sync(conf = config, input_map = input_map)
  dpinput_write(project_path = ".", input_d = synced_map)
}

build_and_deploy_local_test_daap <- function(dev_fixtures_daap_dir) {
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
}