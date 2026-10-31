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

