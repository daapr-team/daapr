local_git_repo <- function(dir, remote_url = NULL, env = parent.frame()) {
  repo <- git2r::init(path = dir)
  git2r::config(repo = repo, user.name = "Test User", user.email = "test@example.com")
  writeLines("x", fs::path(dir, "file.txt"))
  git2r::add(repo = repo, path = fs::path(dir, "file.txt"))
  git2r::commit(repo = repo, message = "init")
  if (!is.null(remote_url)) {
    git2r::remote_add(repo = repo, name = "origin", url = remote_url)
  }
  repo
}

test_that("returns git info from the last commit of project_path", {
  project <- withr::local_tempdir()
  local_git_repo(project, remote_url = "https://github.com/example/dp-project.git")

  git_info <- gitinfo_validate(project_path = project)

  expect_equal(git_info$git_uname, "Test User")
  expect_equal(git_info$git_uemail, "test@example.com")
  expect_match(git_info$git_sha, "^[0-9a-f]{40}$")
})

test_that("reads the remote of project_path, not of the working directory", {
  project <- withr::local_tempdir()
  local_git_repo(project, remote_url = "https://github.com/example/dp-project.git")

  # Run from inside a different repo with a different remote
  other <- withr::local_tempdir()
  local_git_repo(other, remote_url = "https://github.com/example/other-repo.git")
  withr::local_dir(other)

  git_info <- gitinfo_validate(project_path = project)

  expect_equal(git_info$remote_url, "https://github.com/example/dp-project.git")
})

test_that("works when the working directory is not a git repo", {
  project <- withr::local_tempdir()
  local_git_repo(project, remote_url = "https://github.com/example/dp-project.git")
  withr::local_dir(withr::local_tempdir())

  git_info <- gitinfo_validate(project_path = project)

  expect_equal(git_info$remote_url, "https://github.com/example/dp-project.git")
})
