
# TODO: this is just a skeleton of an idea so far

clone_local_dp_test <- function(){
  # create temp dir; random dir name within tempdir() since tempdir() is per-session
  temp_dp_dir <- tempfile(pattern="dir")
  dir.create(temp_dp_dir)
  temp_repo_dir <- file.path(temp_dp_dir, "dp-test")
  # clone dp-test to temp dir
  dp_test_url <- "https://github.com/daapr-team/dp-test.git"
  git2r::clone(url=dp_test_url, local_path=temp_repo_path)
  # return temp dir to use in tests
  return(temp_repo_dir)
}
