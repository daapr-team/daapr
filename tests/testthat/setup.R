# Because e2e tests will install packages, isolate tests from the  R cache dir
# https://github.com/r-lib/pkgcache#using-pkgcache-in-cran-packages
withr::local_envvar(
  R_USER_CACHE_DIR = tempfile(),
  .local_envir = teardown_env()
)
