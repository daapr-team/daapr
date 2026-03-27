test_that("everything works end to end", {
  starting_dir <- getwd()
  starting_daapr_version <- packageVersion("daapr")
  installed.packages()
  tmp_dirs <- init_local_test_daap()
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
  lock_contents <- renv::lockfile_read()
  loaded_daapr <- packageDescription("daapr")
  expect_equal(lock_contents$Packages$daapr$Version, loaded_daapr$Version)
  # do we want a check on lock_contents$Packages$daapr$Repository?
  # if using a local dev version from devtools::load_all, packageDescription and 
  # RemoteType/RemoteUrl will be NA and Version will be from DESCRIPTION file

  # TODO: Compare contents of any files that are in inst (global.R, README.Rmd but params get filled in)
  temp_daap_global0_hash <- unname(tools::md5sum(file.path(tmp_dirs$temp_dp_project_dir, "R/global.R")))
  inst_global0_hash <- unname(tools::md5sum(system.file("global.R", package="daapr")))
  expect_equal(temp_daap_global0_hash, inst_global0_hash)
  temp_daap_readme_hash <- unname(tools::md5sum(file.path(tmp_dirs$temp_dp_project_dir, "README.Rmd")))
  inst_readme_hash <- unname(tools::md5sum(system.file("README.Rmd", package="daapr")))
  expect_equal(temp_daap_readme_hash, inst_readme_hash)

  expect_equal(getwd(), starting_dir)

  # On Mac, the temp dir in /var is a symlink to /private/var that needs to be normalized
  expect_equal(renv::project(), normalizePath(tmp_dirs$temp_dp_project_dir))

  # change to tmp test daap directory
  setwd(tmp_dirs$temp_dp_project_dir)

  # Create default code
  dpcode_add(project_path = ".")
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
  # commit

  add_test_daap_inputs(daapr_fixtures_dir = tmp_dirs$daapr_fixtures_dir)

  build_and_deploy_local_test_daap(dev_fixtures_daap_dir = tmp_dirs$dev_fixtures_daap_dir)

  # TODO: the better approach is to use withr::with_tempdir(), but it's complicated since the temp dir
  # is created in init_local_test_daap. Maybe we should add an arg to init_local_test_daap to specify
  # a temp dir name?
  fs::dir_delete(tmp_dirs$temp_dp_project_dir)
  fs::dir_delete(file.path(tempdir(), deployed_dir_name))
})
