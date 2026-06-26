test_that("everything works end to end", {
  
  # skip_on_ci()
  starting_dir <- getwd()
  starting_daapr_version <- packageVersion("daapr")

  # TODO README.Rmd rendering will print messages here
  e2e_tempdir <- withr::local_tempdir()
  helpers_file <- testthat::test_path("helpers_dp-test.R")
  # TODO have this first r_session be separate from all remaining r_session calls
  # Use R's file.copy() instead of cp -PR so renv doesn't fail on extended
  # attribute permissions in the temp library created by R CMD check on macOS.
  rsession <- callr::r_session$new(options = callr::r_session_options(
    env = c(RENV_CONFIG_COPY_METHOD = "R")
  ))
  session1_output <- rsession$run(function(dir, helpers_file){
    # Try load_all() for dev testing; fall back to installed package during R CMD check
    # where the source tree isn't available
    loaded <- tryCatch(
      { pkgload::load_all(); TRUE },
      error = function(e) FALSE
    )
    if (!loaded) {
      library(daapr)
      source(helpers_file, local = FALSE)
    }
    tmp_dirs <- init_local_test_daap(dir)
    list(tmp_dirs, packageVersion("daapr"))
  }, args=list(e2e_tempdir, helpers_file))
  tmp_dirs <- session1_output[[1]]
  session1_daapr_version <- session1_output[[2]]
  # structure/contents of daap config
  expected_files <- c(
    ".daap/daap_config.yaml",
    ".gitignore",
    ".renvignore",
    ".Rprofile",
    "R/global.R",
    "README.Rmd",
    "renv.lock"
  )
  # TODO: can we make label more informative?
  purrr::walk(expected_files, .f=function(f){
    expect_true(file.exists(file.path(tmp_dirs$temp_dp_project_dir, f)), label=f)
  })
  expected_dirs <- c("input_files", "output_files")
  purrr::walk(expected_dirs, .f=function(d){
    expect_true(dir.exists(file.path(tmp_dirs$temp_dp_project_dir, d)), label=d)
  })
  # daap config contents
  daap_config <- yaml::read_yaml(file.path(tmp_dirs$temp_dp_project_dir, ".daap/daap_config.yaml"))
  expect_equal(daap_config$project_name, daap_dir_name)
  expect_match(daap_config$board_params_set_dried, regexp="^board_params_set_local\\(folder =")
  # TODO: expect project_path is NOT in the config
  # TODO: update check on contents of renv.lock after we fix renv set up
  lock_contents <- renv::lockfile_read(file=file.path(tmp_dirs$temp_dp_project_dir, "renv.lock"))
  loaded_daapr_version <- packageDescription("daapr")$Version
  expect_contains(names(lock_contents$Packages), "daapr")
  expect_equal(lock_contents$Packages$daapr$Version, loaded_daapr_version)

  # Compare contents of any files that are in inst to tmp folder (global.R, README.Rmd)
  temp_daap_global0_hash <- unname(tools::md5sum(file.path(tmp_dirs$temp_dp_project_dir, "R/global.R")))
  inst_global0_hash <- unname(tools::md5sum(system.file("global.R", package="daapr")))
  expect_equal(temp_daap_global0_hash, inst_global0_hash)
  temp_daap_readme_hash <- unname(tools::md5sum(file.path(tmp_dirs$temp_dp_project_dir, "README.Rmd")))
  inst_readme_hash <- unname(tools::md5sum(system.file("README.Rmd", package="daapr")))
  expect_equal(temp_daap_readme_hash, inst_readme_hash)

  expect_equal(getwd(), starting_dir)

  # On Mac, the temp dir in /var is a symlink to /private/var that needs to be normalized
  session2_output <- rsession$run(function(){
    list(
      renv::project(),
      packageVersion("daapr")
    )
  })
  rsession_renv_project <- session2_output[[1]]
  session2_daapr_version <- session2_output[[2]]
  expect_equal(rsession_renv_project, normalizePath(tmp_dirs$temp_dp_project_dir))

  # Create default code
  # suppress renv messages and pre-flight validation (daapr may be installed from
  # an unknown/local source during dev/testing, which renv::snapshot() rejects)
  session3_daapr_version <- rsession$run(function(dir){
    # pkgload::load_all()
    withr::local_options(list(renv.verbose = FALSE, renv.config.snapshot.validate = FALSE))
    daapr::dpcode_add(project_path = dir)
    packageVersion("daapr")
  }, args=list(tmp_dirs$temp_dp_project_dir))
  temp_daap_global1_hash <- unname(tools::md5sum(file.path(tmp_dirs$temp_dp_project_dir, "R/global.R")))
  fixture_global1_hash <- unname(tools::md5sum(file.path(tmp_dirs$dev_fixtures_daap_dir, "R/global.R")))
  expect_equal(temp_daap_global1_hash, fixture_global1_hash)
  temp_daap_journal_hash <- unname(tools::md5sum(file.path(tmp_dirs$temp_dp_project_dir, "dp_journal.Rmd")))
  inst_journal_hash <- unname(tools::md5sum(system.file("dp_journal_targets.Rmd", package="daapr")))
  fixture_journal_hash <- unname(tools::md5sum(file.path(tmp_dirs$dev_fixtures_daap_dir, "dp_journal.Rmd")))
  expect_equal(temp_daap_journal_hash, inst_journal_hash)
  # TODO: use this comparison to the fixture later, once we finish combined daapr release 1
  # expect_equal(temp_daap_journal_hash, fixture_journal_hash)
  temp_daap_dpmake_hash <- unname(tools::md5sum(file.path(tmp_dirs$temp_dp_project_dir, "dp_make.R")))
  inst_dpmake_hash <- unname(tools::md5sum(system.file("_targets.R", package="daapr")))
  expect_equal(temp_daap_dpmake_hash, inst_dpmake_hash)
  # renv.lock updated with new deps
  lock_contents_2 <- renv::lockfile_read(file=file.path(tmp_dirs$temp_dp_project_dir, "renv.lock"))
  expect_null(lock_contents_2$Packages$drake)
  expect_false(is.null(lock_contents_2$Packages$targets))
  # commit

  session4_daapr_version <- rsession$run(function(daap_dir, fixtures_dir){
    # pkgload::load_all()
    setwd(daap_dir)
    renv::load(daap_dir)
    add_test_daap_inputs(daapr_fixtures_dir = fixtures_dir)
    packageVersion("daapr")
  }, args=list(tmp_dirs$temp_dp_project_dir, tmp_dirs$daapr_fixtures_dir))
  # Check contents of pinned data vs fixture
  temp_input_pin_dm_files <- list.files(file.path(tmp_dirs$temp_dp_board_dir, "dpinput/dm/"), full.names = TRUE)
  temp_input_pin_dm <- file.path(rev(sort(temp_input_pin_dm_files))[1], "dm.rds")
  # TODO naming inconsistency add pin? see two cases below as well
  deployed_input_fixture_dm_files <- list.files(file.path(tmp_dirs$dev_fixtures_deployed_dir, "dpinput/dm/"), full.names = TRUE)
  deployed_input_fixture_dm <- file.path(rev(sort(deployed_input_fixture_dm_files))[1], "dm.rds")
  expect_identical(readRDS(temp_input_pin_dm), readRDS(deployed_input_fixture_dm))
  temp_input_pin_rs_files <- list.files(file.path(tmp_dirs$temp_dp_board_dir, "dpinput/rs_onco_imwg/"), full.names = TRUE)
  temp_input_pin_rs <- file.path(rev(sort(temp_input_pin_rs_files))[1], "rs_onco_imwg.rds")
  deployed_input_fixture_rs_files <- list.files(file.path(tmp_dirs$dev_fixtures_deployed_dir, "dpinput/rs_onco_imwg/"), full.names = TRUE)
  deployed_input_fixture_rs <- file.path(rev(sort(deployed_input_fixture_rs_files))[1], "rs_onco_imwg.rds")
  expect_identical(readRDS(temp_input_pin_rs), readRDS(deployed_input_fixture_rs))
  # check temp folder daap_input.yaml nodes
  temp_input_yaml <- yaml::read_yaml(file.path(tmp_dirs$temp_dp_project_dir, ".daap/daap_input.yaml"))
  expect_setequal(names(temp_input_yaml), c("dm", "rs_onco_imwg"))

  session5_daapr_version <- rsession$run(function(daap_dir, fixtures_dir){
    build_and_deploy_local_test_daap(dev_fixtures_daap_dir = fixtures_dir)
    packageVersion("daapr")
  }, args=list(tmp_dirs$temp_dp_project_dir, tmp_dirs$dev_fixtures_daap_dir))
  rsession$kill()
  temp_log_yaml <- yaml::read_yaml(file.path(tmp_dirs$temp_dp_project_dir, ".daap/daap_log.yaml"))
  temp_log_node <- setdiff(names(temp_log_yaml), "HEAD")
  expect_length(temp_log_node, 1)
  expect_true(stringr::str_detect(temp_log_node, "^rds_log_"))
  # TODO check that daap log pin_version matches temp deployed pin pin_hash first 8 characters? data.txt
  temp_output_pin_files <- list.files(file.path(tmp_dirs$temp_dp_board_dir, "daap/dp-test-main"), full.names = TRUE)
  temp_output_pin <- file.path(rev(sort(temp_output_pin_files))[1], "dp-test-main.rds")
  temp_output_rds <- readRDS(temp_output_pin)
  deployed_output_fixture_files <- list.files(file.path(tmp_dirs$dev_fixtures_deployed_dir, "daap/dp-test-main"), full.names = TRUE)
  deployed_output_fixture <- file.path(rev(sort(deployed_output_fixture_files))[1], "dp-test-main.rds")
  deployed_output_rds <- readRDS(deployed_output_fixture)
  expect_equal(temp_output_rds$output, deployed_output_rds$output) # equal instead of idential to allow for IDate integer/double differences

  # Test reading from deployed daap
  daap_config_hydrated <- dpconf_get(project_path = tmp_dirs$temp_dp_project_dir)
  expect_s3_class(daap_config_hydrated, "local_board") # NOTE: it's weird this is a board class and not a config class
  expect_equal(daap_config_hydrated$project_name, daap_dir_name)
  tmp_board <- dp_connect(board_params = daap_config_hydrated$board_params, 
                          creds = daap_config_hydrated$creds)
  expect_s3_class(tmp_board, "pins_board_folder")
  expect_equal(normalizePath(as.character(tmp_board$path)), 
               normalizePath(file.path(daap_config_hydrated$board_params$folder, "daap")))
  tmp_board_list <- dp_list(board_object = tmp_board)
  expect_equal(nrow(tmp_board_list), 1)
  # TODO check metadata in board log, such as version
  tmp_daap <- dp_get(board_object = tmp_board, data_name = tmp_board_list$dp_name)
  expect_setequal(names(tmp_daap), c("README", "input", "output"))
  tmp_daap_input1 <- tmp_daap$input$dm(config = daap_config_hydrated)
  expect_s3_class(tmp_daap_input1, "data.frame")
  expect_identical(tmp_daap_input1, readRDS(temp_input_pin_dm))
  expect_identical(tmp_daap$output, temp_output_rds$output)

  # Checking that daapr versions used in each R session match the version used to launch tests
  expect_equal(as.character(session1_daapr_version), loaded_daapr_version)
  expect_equal(as.character(session2_daapr_version), loaded_daapr_version)
  expect_equal(as.character(session3_daapr_version), loaded_daapr_version)
  expect_equal(as.character(session4_daapr_version), loaded_daapr_version)
  expect_equal(as.character(session5_daapr_version), loaded_daapr_version)
  # Cleanup
  # fs::dir_delete(tmp_dirs$temp_dp_project_dir)
  # fs::dir_delete(tmp_dirs$temp_dp_board_dir)
})
