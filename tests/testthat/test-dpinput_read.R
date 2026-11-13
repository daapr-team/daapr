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

test_that("project_path locates daap_input.yaml from another directory", {
  project <- fixture_project()
  withr::local_dir(withr::local_tempdir())

  dpinput <- dpinput_read(project_path = project)

  expect_named(dpinput, expected_inputs(project))
  expect_true(all(vapply(dpinput, is.function, logical(1))))
})

test_that("an explicit daap_input_yaml takes precedence over project_path", {
  project <- fixture_project()
  daap_input_yaml <- yaml::read_yaml(fs::path(project, ".daap", "daap_input.yaml"))

  dpinput <- dpinput_read(
    daap_input_yaml = daap_input_yaml,
    project_path = "/nonexistent/dp"
  )

  expect_named(dpinput, expected_inputs(project))
})
