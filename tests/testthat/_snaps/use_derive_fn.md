# generated file content matches template

    Code
      cat(readLines(path), sep = "\n")
    Output
      derive_ae <- function(data_files_read, config) {
      
        # This is just example code! Replace this with your actual derivation code.
        derived_ae <- data_files_read$ae(config = config) |>
          mutate(new_col = old_col + 5)
      
        return(derived_ae)
      }

---

    Code
      cat(readLines(path), sep = "\n")
    Output
      derive_ae_safety <- function(data_files_read, config) {
      
        # This is just example code! Replace this with your actual derivation code.
        derived_ae <- data_files_read$ae(config = config) |>
          mutate(new_col = old_col + 5)
      
        return(derived_ae)
      }

# prints a targets dp_make.R snippet by default

    Code
      cat(dp_make_snippet(".", "ae"), sep = "\n")
    Output
      # Add to the list of targets:
      tar_target(ae, derive_ae(data_files_read = data_files_read, config = config)),
      
      # Add to the `output` list in dp_structure():
      ae = ae

---

    Code
      cat(dp_make_snippet(".", "ae", "safety"), sep = "\n")
    Output
      # Add to the list of targets (if a `safety` target already exists, add `ae = ae_safety` to its list instead):
      tar_target(ae_safety, derive_ae_safety(data_files_read = data_files_read, config = config)),
      tar_target(safety, list(
        ae = ae_safety
      )),
      
      # Add to the `output` list in dp_structure():
      safety = safety

# prints a drake dp_make.R snippet when dp_make.R uses drake

    Code
      cat(dp_make_snippet(".", "ae"), sep = "\n")
    Output
      # Add to drake_plan():
      ae = derive_ae(data_files_read = data_files_read, config = config),
      
      # Add to the `output` list in dp_structure():
      ae = ae

---

    Code
      cat(dp_make_snippet(".", "ae", "safety"), sep = "\n")
    Output
      # Add to drake_plan() (if a `safety` target already exists, add `ae = ae_safety` to its list instead):
      ae_safety = derive_ae_safety(data_files_read = data_files_read, config = config),
      safety = list(
        ae = ae_safety
      ),
      
      # Add to the `output` list in dp_structure():
      safety = safety

