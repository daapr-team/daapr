#' helper function to return downgrade messages for lifecycle warnings
#' @noRd
downgrade_message <- function() {
  return(c(
    " " = "This data product was built with a legacy version of pins. To access a legacy
    data product, downgrade pins and dpi packages using:",
    " " = "remotes::install_github(repo = 'amashadihossein/pins')",
    " " = "remotes::install_github(repo = 'amashadihossein/dpi@v0.0.0.9008')",
    " " = "",
    " " = "To continue building a legacy data product, downgrade all daapr packages:",
    " " = "remotes::install_github(repo = 'amashadihossein/dpbuild@v0.0.0.9106')",
    " " = "remotes::install_github(repo = 'amashadihossein/dpdeploy@v0.0.0.9016')",
    " " = "remotes::install_github(repo = 'amashadihossein/daapr@v0.0.0.9006')"
  ))
}


#' @title Hydrate a dried called function
#' @description execute and returns the value of function call given its textual
#'  (dried) representation
#' @param dried_fn a function called
#' @return value of the called function given its textual representation
#' @examples \dontrun{
#' fn_hydrate(fn_dry(sum(log(1:10))))
#' }
#' @keywords internal
fn_hydrate <- function(dried_fn) {
  return(eval(rlang::parse_expr(dried_fn)))
}

#' @title Get Data Product Name
#' @description A helper function that build data product name (i.e. what the pin is going to be called)
#' @param data_object Data Object. It anticipates project_name and branch_name to be attributes of this data object
#' @return dp_name a character that will be tagged back as attribute to data_object
#' @export
dpname_get <- function(data_object) {
  dp_name <- dpname_make(
    project_name = attributes(data_object)$project_name,
    branch_name = attributes(data_object)$branch_nam
  )
  return(dp_name)
}


#' @title Make Data Product Name
#' @description A helper function that build data product name (i.e. what the pin is going to be called)
#' @param project_name Project name
#' @param branch_name Branch name
#' @return dp_name a character that will be tagged back as attribute to data_object
#' @export
dpname_make <- function(project_name, branch_name) {
  dp_name <- glue::glue("{project_name}_{branch_name}")
  dp_name <- gsub(pattern = "_", replacement = "-", dp_name)
  dp_name <- as.character(dp_name)
  return(dp_name)
}


#' @title Get Pins Version Pre Deploy
#' @description  This get the pins version pre-deploy
#' @param d data object
#' @param pin_name what the pin will be named. For data products, it is encoded in dp_param
#' @param pin_description what the pin description will be. For data products, it is encoded in dp_params
#' @param type File type used to save the data product, default RDS
#' @return a character version
#' @importFrom dplyr .data
#' @keywords internal
get_pin_version <- function(d, pin_name, pin_description, type = "rds") {
  withr::local_options(list(pins.quiet = TRUE))
  pin_name <- as.character(pin_name)
  pin_description <- as.character(pin_description)

  temp_board_folder <- pins::board_temp(versioned = TRUE)

  pin_name_exists <- pins::pin_exists(board = temp_board_folder, name = pin_name)

  if (pin_name_exists) {
    pins::pin_delete(names = pin_name, board = temp_board_folder)
  }

  pins::pin_write(
    x = d,
    name = pin_name,
    board = temp_board_folder,
    description = pin_description,
    type = type
  )

  pin_version <- pins::pin_versions(
    name = pin_name,
    board = temp_board_folder
  ) %>% dplyr::pull(.data$hash)
  pins::pin_delete(names = pin_name, board = temp_board_folder)

  return(pin_version)
}


#' @title Get Readme to be appended to the data object
#' @description  This function builds readme metadata
#' @param d data object
#' @param general_note a character string to be added to general notes for this data object branch/commit
#' @return readme text
#' @export
readme_get <- function(d, general_note) {
  readme <- list()
  readme$general_note <- general_note
  readme$input <- paste("Input data includes", paste(setdiff(names(d$input), "metadata"), collapse = ", "))

  readme$output <- paste("This contains the following:", paste(names(d$output), collapse = ", "))

  readme$exploratory <- paste("This contains the following:", paste(names(d$exploratory), collapse = ", "))

  readme$metadata <- paste("This contains the following:", paste(names(d$metadata), collapse = ", "))

  readme <- readme[c("general_note", setdiff(names(d), "README"))]

  return(readme)
}

#' @title Get sha1 signature for a table
#' @description  This function is a wrapper around digest::sha1 to handle exotic column classes
#' @param d data.frame
#' @return tbsig a character string
#' @export
tbsig_get <- function(d) {
  if (!inherits(d, "data.frame")) {
    stop("tbsig is only for data.frames. Ensure d is a data.frame")
  }

  supported_classes <- c(
    "numeric", "integer", "character",
    "factor", "Date", "logical", "POSIXlt",
    "POSIXct"
  )
  d1 <- as.data.frame(lapply(d, FUN = function(col_i) {
    this_class <- class(col_i)
    if (any(!this_class %in% supported_classes)) {
      class(col_i) <- c(this_class, setdiff("character", this_class))
    }
    col_i
  }))

  attributes(d1) <- attributes(d)

  tbsig <- digest::sha1(x = d1, environment = FALSE)

  return(tbsig)
}


#' @title Update exotic column classes of data.frames in a list for sha1 signature
#' @description  This function is to be used before digest::sha1 to handle exotic column classes
#' @param l list
#' @return list
#' @keywords internal
make_sha1_compatible <- function(l) {
  if (setdiff(class(l), "dp") != "list") {
    stop("lssig is only for lists. Ensure l is a list")
  }

  supported_classes <- c(
    "numeric", "integer", "character",
    "factor", "Date", "logical", "POSIXlt",
    "POSIXct"
  )

  l1 <- lapply(l, FUN = function(node) {
    if (any(class(node) == "data.frame")) {
      d1 <- as.data.frame(lapply(node, FUN = function(col_i) {
        this_class <- class(col_i)
        if (any(!this_class %in% supported_classes)) {
          class(col_i) <- c(this_class, setdiff("character", this_class))
        }
        col_i
      }))

      attributes(d1) <- attributes(node)
      d1
    } else if (any(class(node) == "list")) {
      make_sha1_compatible(node)
    } else {
      node
    }
  })

  return(l1)
}


#' @title Make names code friendly
#' @description  This function tries to provide a more sensible mapping of names to their code friendly version than make.names
#' @param x a character string to be converted
#' @param make_unique if TRUE it ensures each element of a vector names end up being unique
#' @return the code friendly converted character string
#' @export
make_names_codefriendly <- function(x, make_unique = TRUE) {
  x <- trimws(x) %>%
    paste0(ifelse(grepl(pattern = "^[0-9]", x = .), "var_", ""), .) %>%
    gsub("(?<![0-9])\\-", "-", x = ., perl = TRUE) %>%
    gsub("\\&", "_and_", x = .) %>%
    gsub("\\@", "_at_", x = .) %>%
    gsub("\\+", "_pos_", x = .) %>%
    gsub(",", "_comma_", x = .) %>%
    gsub("\\/", "_fwdslsh_", x = .) %>%
    gsub("\\(|\\)", "\\.", x = .) %>%
    gsub("\\%", "percent_", x = .) %>%
    gsub("\\#", "num_", x = .) %>%
    gsub(" ", "_", x = .)

  if (make_unique) {
    return(make.names(names = x, unique = TRUE))
  }

  return(make.names(names = x, unique = FALSE))
}


#' @title Make dpinput names simplified
#' @description  This function tries to drop the full descriptive name of dpinput
#' elements for code aesthetics
#' @param x a character string of the form `{path}/{file_name.extension}/{sha1}`
#' which will be converted to a character string of the form `{file_name}`
#' @param make_unique if TRUE it ensures each element of a vector names end up
#' being unique. If not it errors if not simplified names not unique.
#' @return the code friendly converted character string
#' @keywords internal
dpinputnames_simplify <- function(x, make_unique = FALSE) {
  simplified_inputnames <- fs::path_split(x) %>%
    sapply(X = ., function(x) {
      x_trimmed <- x
      if (length(x) > 1) {
        x_trimmed <- fs::path_ext_remove(rev(x)[2])
      }
      x_trimmed
    })

  if (make_unique) {
    return(make.unique(simplified_inputnames))
  }

  if (any(dups <- duplicated(simplified_inputnames))) {
    stop(paste("simplified names", paste0(which(dups), collapse = ", "), "are dupclicate which are not allowed"))
  }

  return(simplified_inputnames)
}


#' @title Clean input_map
#' @description  This function drops unsynced inputs from the input map
#' and cleans names
#' @param input_map synced mapped object as returned by `dpinput_map`
#' @param remove_id a vector of input_data ids to remove. This is for convenience
#' as setting the input_manifest field `to_be_synced` to FALSE can achieve the
#' same thing. The default value of `character(0)` limits removal to any row
#' with `to_be_synced == FALSE`
#' @param force_cleanname T/F, if TRUE it ensures each input id name ends up
#' being unique. If FALSE, it won't clean names unless names are already unique
#' @return input_map pruned and with cleaner names
#' @export
inputmap_clean <- function(input_map, remove_id = character(0), force_cleanname = FALSE) {
  input_map$input_manifest <- input_map$input_manifest %>%
    dplyr::mutate(to_be_synced = replace(.data$to_be_synced, .data$id %in% remove_id, FALSE))

  input_map$input_manifest <- input_map$input_manifest %>% dplyr::filter(.data$to_be_synced)
  input_map$input_obj <- input_map$input_obj[input_map$input_manifest$id]

  if (!inherits(try(dpinputnames_simplify(input_map$input_manifest$id)), "try-error") || force_cleanname) {
    input_map$input_manifest <- input_map$input_manifest %>%
      dplyr::mutate(id = dpinputnames_simplify(.data$id, make_unique = force_cleanname))

    names(input_map$input_obj) <-
      dpinputnames_simplify(names(input_map$input_obj),
        make_unique = force_cleanname
      )

    input_map$input_obj <- sapply(names(input_map$input_obj), function(name_i) {
      input_map$input_obj[[name_i]]$metadata$id <- name_i
      input_map$input_obj[[name_i]]
    }, simplify = FALSE, USE.NAMES = TRUE)
  }

  return(input_map)
}


#' @title Purge Local Pins Cache
#' @description  It completely deletes content of local cache. Use with care!
#' @param path_cache path to pins cache. Default is `pins::board_cache_path()`
#' @keywords internal
purge_local_cache <- function(path_cache = pins::board_cache_path()) {
  fs::dir_delete(fs::dir_ls(path_cache))
}

#' @title Gets cross OS File Name
#' @description  It drops extension that can be OS-specific
#' @param fl just the file name e.g. README.RMD
#' @param package package name e.g. daapr
#' @keywords internal
flname_xos_get <- function(fl, package = "daapr") {
  pkg_path <- system.file(package = package)
  fl_name <- fs::path_ext_remove(fl)
  fl_path <- Sys.glob(glue::glue("{pkg_path}/{fl_name}.*"))
  flname <- basename(fl_path)
  return(flname)
}


#' @title Check pins package compatibility
#' @description Check pins package compatibility
#' @param project_path path to project folder
#' @keywords internal
check_pins_compatibility <- function(project_path = ".") {
  read_conf_file <- dpconf_read(project_path = project_path)

  if ("is_legacy" %in% names(read_conf_file)) {
    is_legacy_dp <- read_conf_file$is_legacy
  } else {
    is_legacy_dp <- TRUE
  }

  is_installed_pins_version_legacy <- utils::packageVersion(pkg = "pins") < "1.2.0"

  pins_version_message <- glue::glue(
    'This data product was built with a legacy version of pins.
    Please downgrade pins and all daapr packages using
    remotes::install_github(repo = "amashadihossein/pins")
    remotes::install_github(repo = "amashadihossein/dpi@v0.0.0.9008")
    remotes::install_github(repo = "amashadihossein/dpbuild@v0.0.0.9106")
    remotes::install_github(repo = "amashadihossein/dpdeploy@v0.0.0.9016")
    remotes::install_github(repo = "amashadihossein/daapr@v0.0.0.9006")'
  )

  if (any(is_legacy_dp, is_installed_pins_version_legacy)) {
    stop(cli::cli_alert_danger(pins_version_message))
  }
}


#' @title Validate git info for deploy
#' @description Validates and extracts gitinfo per deploy requirements
#' @param project_path path to project
#' @param verbose F if TRUE prints process details
#' @return git_info, a list containing git information
#' @keywords internal
gitinfo_validate <- function(project_path, verbose = FALSE) {
  #--- Check git set up-------
  repo <- git2r::repository(path = project_path)
  last_commit <- git2r::last_commit(repo = repo)

  git_info_valid <- nchar(git_sha <- as.character(last_commit$sha)) > 0 &
    nchar(git_uname <- as.character(last_commit$author$name)) > 0 &
    nchar(git_uemail <- as.character(last_commit$author$email)) > 0 &
    nchar(git_timestamp <- paste0(last_commit$author$when, collapse = " ")) > 0

  if (!git_info_valid) {
    stop(cli::format_error(glue::glue(
      "Failed to retrieve git info.",
      " Info retrieved from last commit git sha: {git_sha},",
      " author: {git_uname}, email: {git_uemail}.",
      " Ensure dp_commit is executed before dpdeploy"
    )))
  }
  git_info <- list(
    git_sha = git_sha, git_uname = git_uname,
    git_uemail = git_uemail, git_timestamp = git_timestamp
  )

  #-----Check remote git url-------------
  remote_url <- try(git2r::remote_url(repo = ".", remote = git2r::remotes()), silent = TRUE)
  has_remote_url <- class(remote_url) != "try-error"
  if (verbose) {
    if (has_remote_url) {
      print(glue::glue("has remote git url ", paste(remote_url, collapse = ", and ")))
    }
    if (!has_remote_url) {
      print("No remote git url found. Have you pushed to GitHub before deploy?")
    }
  }

  git_info$remote_url <- remote_url

  return(git_info)
}


#' @title Update dpboard log
#' @description Updates the metadata associated with the board and retrievable
#' with dp_list. When deploying dlog is needed when archiving dp_name and
#' pin_version are needed.
#' @param conf output of `dpconf_get`
#' @param git_info a list returned from `gitinfo_validate`
#' @param dlog daap_log. This is only needed when adding record
#' @param dp_name name of the pin to be archived. Ignored when dlog is provided.
#' @param pin_version version of the pin to be archived.
#' Ignored when dlog is provided
#' @return TRUE
#' @keywords internal
dpboardlog_update <- function(conf, git_info, dlog = NULL,
                              dp_name = character(0),
                              pin_version = character(0)) {
  board_object <- dp_connect(
    board_params = conf$board_params, creds = conf$creds,
    board_subdir = "daap/"
  )

  if (board_object$board == "pins_board_folder") {
    in_daap_dir <- rev(unlist(strsplit(
      x = board_object$path,
      split = "_|-|/"
    )))[1] == "daap"
  } else if (board_object$board == "pins_board_labkey") {
    in_daap_dir <- rev(unlist(strsplit(
      x = board_object$subdir,
      split = "/"
    )))[1] == "daap"
  } else {
    in_daap_dir <- rev(unlist(strsplit(
      x = board_object$prefix,
      split = "/"
    )))[1] == "daap"
  }

  if (!in_daap_dir) {
    stop(cli::format_error(glue::glue(
      "dpboard is not pointing to daap ",
      "subfolder on remote. Check board."
    )))
  }

  dpboard_log <- tryCatch(
    expr = {
      if (board_object$board == "pins_board_labkey") {
        pinsLabkey::pin_read(
          name = "dpboard-log",
          board = board_object
        )
      } else {
        pins::pin_read(
          name = "dpboard-log",
          board = board_object
        )
      }
    },
    error = function(er) {
      msg <- conditionMessage(er)

      invisible(structure(msg, class = "try-error"))
    }
  )


  if (!"data.frame" %in% class(dpboard_log)) {
    dpboard_log <- NULL
  }

  if (length(dlog) == 0) {
    if (length(dp_name) == 0 || length(pin_version) == 0) {
      stop(cli::format_error(glue::glue(
        "Cannot update. dlog, dp_name and ",
        "pin_version all have length 0"
      )))
    }
    if (is.null(dpboard_log)) {
      stop(cli::format_error(glue::glue(
        "dpboard-log was not found. Make sure ",
        "dpboard-log exists for this board"
      )))
    }

    # update the records based on composite key dp_name, dp_version, and git_sha
    dpboard_log_tmp <- dpboard_log %>%
      dplyr::filter(.data$dp_name != dp_name | .data$pin_version != pin_version |
        .data$git_sha != git_info$git_sha)

    tmp <- dpboard_log %>%
      dplyr::filter(.data$dp_name == dp_name & .data$pin_version == pin_version &
        .data$git_sha == git_info$git_sha)
    if (nrow(tmp) == 0) {
      stop(cli::format_error(glue::glue(
        "The provided compbination of dp_name ",
        "{dp_name}, dp_version {dp_version}, ",
        "and git_sha {git_info$git_sha} is not",
        " in dpboard-log. Verify the values ", "
                                        are correct!"
      )))
    }

    tmp <- tmp %>% dplyr::mutate(archived = TRUE)
    dpboard_log <- dplyr::bind_rows(dpboard_log_tmp, tmp) %>%
      dplyr::distinct()

    if (board_object$board == "pins_board_labkey") {
      pinsLabkey::pin_write(
        x = dpboard_log,
        type = "rds",
        name = "dpboard-log",
        board = board_object,
        description = "Data Product Log"
      )
    } else {
      pins::pin_write(
        x = dpboard_log,
        type = "rds",
        name = "dpboard-log",
        board = board_object,
        description = "Data Product Log"
      )
    }

    return(TRUE)
  }

  # Update dp manifest
  daap_log_i <- dlog[dlog$HEAD]

  # Augment with git info
  daap_log_i[[1]]$git_sha <- git_info$git_sha
  daap_log_i[[1]]$commit_time <- git_info$git_timestamp
  daap_log_i[[1]]$git_author_name <- git_info$git_uname
  daap_log_i[[1]]$git_author_email <- git_info$git_uemail
  daap_log_i[[1]]$git_remote <- git_info$remote_url

  # Convert to table
  daap_log_i <- daap_log_i %>%
    dplyr::bind_rows(.id = "rdsid") %>%
    dplyr::mutate(rdsid = gsub("rds_", "", .data$rdsid)) %>%
    dplyr::mutate(dp_name = gsub(pattern = "_", replacement = "-", x = .data$dp_name)) %>%
    dplyr::relocate(.data$dp_name) %>%
    dplyr::mutate(last_deployed = format(Sys.time(), tz = "GMT", usetz = TRUE)) %>%
    dplyr::mutate(archived = FALSE)


  if (is.null(dpboard_log)) {
    dpboard_log <- daap_log_i %>% dplyr::slice(0)
  }

  # Update deploy time if same pin/git_sha exist otherwise append
  tmp <- dpboard_log %>%
    dplyr::filter(.data$dp_name != daap_log_i$dp_name |
      .data$pin_version != daap_log_i$pin_version |
      .data$git_sha != daap_log_i$git_sha)

  dpboard_log <- dplyr::bind_rows(tmp, daap_log_i) %>%
    dplyr::distinct()

  if (board_object$board == "pins_board_labkey") {
    pinsLabkey::pin_write(
      x = dpboard_log,
      type = "rds",
      name = "dpboard-log",
      board = board_object,
      description = "Data Product Log"
    )
  } else {
    pins::pin_write(
      x = dpboard_log,
      type = "rds",
      name = "dpboard-log",
      board = board_object,
      description = "Data Product Log"
    )
  }

  return(TRUE)
}


#' @title Get dlog
#' @description Reads and format daap_log.yml pasting values in key:value
#' pairs at depth 2 with delimitter " > "
#' @return dlog
#' @keywords internal
get_dlog <- function(project_path) {
  dlog <- yaml::read_yaml(file = glue::glue("{project_path}/.daap/daap_log.yaml"))
  dlog <- purrr::modify_depth(
    .x = dlog, .depth = 2, .ragged = TRUE,
    .f = function(x) paste0(x, collapse = " > ")
  )
  return(dlog)
}
