#' @title Adds script templates
#' @description Adds dp_make.R and dp_journal.Rmd to the dp project repo
#' @inheritParams project_path_resolve
#' @param use_targets T/F when TRUE, uses targets instead of drake (recommended)
#' @return repo
#' @export
dpcode_add <- function(project_path = ".", use_targets = T) {
  project_path <- project_path_resolve(project_path)
  if (!fs::dir_exists(project_path)) {
    stop("project_path does not exist")
  }

  if (!is_valid_dp_repository(path = project_path)) {
    stop(cli::format_error(glue::glue(
      "Not a dp repsitory. Run ",
      "`dp_repository_check(\"{project_path}\")`",
      " for details"
    )))
  }

  if (!fs::dir_exists(fs::path(project_path, "R"))) {
    fs::dir_create(fs::path(project_path, "R"))
  }

  if (!use_targets) {
    fs::file_copy(
      path = system.file("dp_make.R", package = "daapr"),
      new_path = project_path
    )

    fs::file_copy(
      path = system.file("global_drake.R", package = "daapr"),
      new_path = fs::path(project_path, "R")
    )
    fs::file_delete(path = fs::path(project_path, "R", "global.R"))
    fs::file_move(
      path = fs::path(project_path, "R", "global_drake.R"),
      new_path = fs::path(project_path, "R", "global.R")
    )
    renv::install(packages = "drake", prompt = FALSE)

    # drake specific journal
    flname_dpjournal <- flname_xos_get(fl = "dp_journal.Rmd")
    fs::file_copy(
      path = system.file(flname_dpjournal, package = "daapr"),
      new_path = project_path
    )
  } else {
    fs::file_copy(
      path = system.file("_targets.R", package = "daapr"),
      new_path = project_path
    )
    fs::file_move(
      path = fs::path(project_path, "_targets.R"),
      new_path = fs::path(project_path, "dp_make.R")
    )

    # targets specific journal (renamed)
    flname_dpjournal <- flname_xos_get(fl = "dp_journal_targets.Rmd")
    fs::file_copy(
      path = system.file(flname_dpjournal, package = "daapr"),
      new_path = project_path
    )
    fs::file_move(
      path = fs::path(project_path, "dp_journal_targets.Rmd"),
      new_path = fs::path(project_path, "dp_journal.Rmd")
    )

    fs::file_copy(
      path = system.file("global_targets.R", package = "daapr"),
      new_path = fs::path(project_path, "R")
    )
    fs::file_delete(path = fs::path(project_path, "R", "global.R"))
    fs::file_move(
      path = fs::path(project_path, "R", "global_targets.R"),
      new_path = fs::path(project_path, "R", "global.R")
    )
    renv::install(packages = c("targets"), prompt = FALSE)
  }

  # snapshot with pkgs in global
  renv::snapshot(prompt = FALSE) # TODO: look into  explicitly adding pkgs

  # commit
  repo <- git2r::repository(path = project_path)
  git2r::add(
    repo = repo, path =
      fs::path(project_path, "dp_make.R")
  )
  git2r::add(
    repo = repo, path =
      fs::path(project_path, "dp_journal.Rmd")
  )
  git2r::add(
    repo = repo, path =
      fs::path(project_path, "R", "global.R")
  )
  git2r::add(
    repo = repo, path =
      fs::path(project_path, "renv.lock")
  )
  repo <- git2r::commit(
    repo = repo,
    message = "Added template code to dp project"
  )
  return(repo)
}
