fixture_project <- function() fs::path_abs(test_path("fixtures", "dp-test"))

expected_inputs <- function(project) {
  names(yaml::read_yaml(fs::path(project, ".daap", "daap_input.yaml")))
}

test_that("default reads daap_input.yaml from the working directory", {
  project <- fixture_project()
  withr::local_dir(project)

  dpinput <- dpinput_read()

  expect_named(dpinput, expected_inputs(project))
  expect_true(all(vapply(dpinput, is.function, logical(1))))
})

test_that("an explicit daap_input_yaml is read from any directory", {
  project <- fixture_project()
  daap_input_yaml <- yaml::read_yaml(fs::path(project, ".daap", "daap_input.yaml"))
  withr::local_dir(withr::local_tempdir())

  dpinput <- dpinput_read(daap_input_yaml = daap_input_yaml)

  expect_named(dpinput, expected_inputs(project))
})
