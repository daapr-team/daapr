Data Product dp-test_main
================

To build and deploy this data product:

### STEP 1: Activate the project

Clone the project, set working directory to project top folder and
activate

``` r
dp_activate(project_path = ".")
```

### STEP 2: Set environment variables

Set `GITHUB_PAT` as environment variable for
<https://github.com/daapr-team/dp-test.git>

``` r
Sys.setenv("GITHUB_PAT" = "<GIHTUB_PAT for the remote url>")
```

Set environment variables as needed to enable evaluation of

`NA`

and order to access the data board

| board_type  | folder                                   |
|:------------|:-----------------------------------------|
| local_board | tests/testthat/fixtures/dp-test_deployed |

### STEP 3: Build

This by convention involves running the main script `dp_make.R`

``` r
targets::tar_make(script = "./dp_make.R")
```

### STEP 4: Deploy

Simple call to `dp_deploy`. By default expects you to be in the project
directory

``` r
dp_deploy()
```
