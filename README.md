
<!-- README.md is generated from README.Rmd. Please edit that file -->

# daapr <img src="man/figures/logo.png" align="right" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/daapr-team/daapr/workflows/R-CMD-check/badge.svg)](https://github.com/daapr-team/daapr/actions)
[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
<!-- badges: end -->

Build and deploy data products in R using the framework of
Data-as-a-Product (DaaP)

## What is a data product?

A **data product** is a versioned dataset that travels with everything
needed to reproduce it: the input data, the logic that derived it, the
package dependencies, and the metadata describing where it all came
from. In daapr, all of that is captured as code and tracked in git, so a
data product can be rebuilt from its configuration alone rather than
passed around as a loose file.

A built data product is an R object containing `README`, `input`,
`output`, and `metadata`, annotated with the project and branch it was
built from.

Data products are deployed to a **board** — a governed data space that
daapr supports on three backends using the `pins` package:

- **s3**, optionally under a prefix within the bucket
- **local** folders, including mounted drives
- **LabKey**

Once deployed, consumers retrieve a data product by name and version
with the same handful of functions no matter which backend it lives on.

## Installation

For released version

``` r
remotes::install_github(repo = "daapr-team/daapr")
```

For dev version

``` r
remotes::install_github(repo = "daapr-team/daapr", ref = "dev")
```

## Quick start

Build and deploy a small data product from the `cars` dataset. See the
[getting started
guide](https://daapr-team.github.io/daapr/articles/daapr.html) for a
more thorough description of each step.

``` r
library(daapr)

# Describe where the data product will live and how to authenticate. These are
# recorded as "dried" calls in the config and hydrated when they are needed, so
# no credentials are ever written to disk.
board_params_set_dried <- fn_dry(board_params_set_s3(
  bucket_name = "my-bucket",
  prefix = "data-products/", # optional; must end in a trailing slash
  region = "us-east-1"
))

creds_set_dried <- fn_dry(creds_set_aws(
  key = Sys.getenv("AWS_ACCESS_KEY_ID"),
  secret = Sys.getenv("AWS_SECRET_ACCESS_KEY")
))

# 1. Initialize: folder structure, git, renv, and daap_config.yaml
dp_repo <- dp_init(
  project_path = "dp_cars",
  project_description = "Cars data product",
  branch_name = "us001",
  branch_description = "User story 1",
  readme_general_note = "Data product to explore cars stopping distance",
  board_params_set_dried = board_params_set_dried,
  creds_set_dried = creds_set_dried,
  github_repo_url = "https://github.com/<org>/dp_cars.git"
)

setwd(dp_repo)
config <- dpconf_get(project_path = ".")

# 2. Sync input data to the board and record what was synced
write.csv(cars, "./input_files/cars.csv", row.names = FALSE)

input_map <- dpinput_map(project_path = ".") |> inputmap_clean()
synced_map <- dpinput_sync(conf = config, input_map = input_map)
dpinput_write(project_path = ".", input_d = synced_map)

# 3. Build the data product
data_files_read <- dpinput_read()

output <- data_files_read$cars(config = config) |>
  dplyr::mutate(dist_m = 0.3048 * dist)

data_object <- dp_structure(
  data_files_read = data_files_read,
  output = output,
  config = config
)

dp_write(data_object = data_object, project_path = ".")

# 4. Commit, push, and deploy
dp_commit(project_path = ".", commit_description = "First dp build")
dp_push(project_path = ".")
dp_deploy()
```

## Using a data product

Consuming a data product needs only the board parameters and credentials
— not the project that built it.

``` r
board_object <- dp_connect(board_params = board_params, creds = creds)

# What is on this board?
dp_list(board_object = board_object)

# Retrieve one, optionally pinned to a specific version
dp <- dp_get(board_object = board_object, data_name = "dp-cars-us001")
```

## Getting started

- [New project
  workflow](https://daapr-team.github.io/daapr/articles/daapr.html) —
  what each step of the lifecycle does
- [A minimalist
  example](https://daapr-team.github.io/daapr/articles/min_wrkfl.html) —
  end to end against an s3 board
- [A minimalist example deployed
  locally](https://daapr-team.github.io/daapr/articles/min_workflow_local.html)
  — the same, with no cloud account needed
- [Read a data
  product](https://daapr-team.github.io/daapr/articles/dp_get.html) —
  connecting to s3, local, and LabKey boards as a consumer
- [Update input
  data](https://daapr-team.github.io/daapr/articles/input_data_update.html)
  and [update build
  logic](https://daapr-team.github.io/daapr/articles/dp_update.html) —
  the two ways a data product changes over time
- [FAQ](https://daapr-team.github.io/daapr/articles/faq.html)

## Project history and older versions

daapr was originally developed at
[amashadihossein/daapr](https://github.com/amashadihossein/daapr),
alongside the separate `dpi`, `dpbuild`, and `dpdeploy` packages.
**Active development has moved to this repository** — and all future
releases will be published here.

As of **1.0.0**, those three packages have been merged into daapr
itself. `library(daapr)` is now all that is needed, and code calling
`dpi::`, `dpbuild::`, or `dpdeploy::` should call `daapr::` instead. See
[NEWS](https://daapr-team.github.io/daapr/news/index.html) for the full
set of breaking changes, including the removal of `qs` support.

The original repositories remain available for anyone who needs an older
package version, but they are no longer maintained:

- [amashadihossein/daapr](https://github.com/amashadihossein/daapr)
- [amashadihossein/dpi](https://github.com/amashadihossein/dpi)
- [amashadihossein/dpbuild](https://github.com/amashadihossein/dpbuild)
- [amashadihossein/dpdeploy](https://github.com/amashadihossein/dpdeploy)

Older versions can be installed from there by pinning a tag, for
example:

``` r
remotes::install_github(repo = "amashadihossein/daapr@v0.2.0")
```
