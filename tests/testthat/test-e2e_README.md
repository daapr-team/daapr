# Fixtures and End-to-End (E2E) Testing

## Overview

The e2e test suite validates the full lifecycle of a `daap`: initialisation,
input ingestion, derivation, build, and deployment. It does this by running the
full workflow in a temporary directory and comparing the output against a saved
reference snapshot — the **fixture** — to catch regressions.

The fixture is a committed set of known-good files. Tests create a fresh daap in
`tempdir()`, step through the same workflow, and assert that outputs match the
fixture (or the installed `inst/` copies, depending on what is being checked).

---

## Directory Structure

```
tests/testthat/
├── fixtures/
│   ├── dp-test/                  # Reference daap files (fixture)
│   │   ├── .daap/                #   daap config, input map, and build log
│   │   ├── R/                    #   derivation scripts (derive_subjects.R, derive_bor.R, global.R)
│   │   ├── dp_journal.RMD        #   analysis journal template
│   │   ├── dp_make.R             #   targets pipeline script
│   │   ├── README.Rmd            #   daap README template
│   │   ├── renv.lock             #   locked package dependencies
│   │   ├── .gitignore
│   │   └── .renvignore
│   ├── dp_board/         # Reference pins board output (fixture)
│   ├── sdtm/                     # Input data used to build the test daap
│   │   ├── dm.csv
│   │   └── rs_onco_imwg.csv
│   ├── create_dp-test.R          # Script to (re)generate the fixtures
│   └── get_pharmaverse_data.R    # Script to download the sdtm input data
├── helpers_dp-test.R             # Shared helper functions for e2e tests
└── test-e2e.R                    # The e2e test suite
```

---

## Helper Functions (`helpers_dp-test.R`)

Two constants are defined at the top of the file and shared across the helpers
and the test suite:

```r
daap_dir_name      <- "dp-test"
deployed_dir_name  <- "dp_board"
```

### `init_local_test_daap(temp_dp_dir)`

Initialises a fresh daap in `tempdir()`. Specifically it:

- Checks that `GITHUB_PAT` is set (required by `dp_init()`)
- Constructs paths to the fixture and temp directories
- Creates a dried board configuration pointing to a local `../dp_board`
  directory relative to the temp daap
- Calls `dp_init()` with a fixed project name, description, branch, and GitHub
  remote URL to produce a reproducible daap skeleton

Returns a named list of paths used by the other helpers and the test suite:

| Name | Description |
|---|---|
| `temp_dp_project_dir` | Absolute path to the new daap in `tempdir()` |
| `temp_dp_board_dir` | Absolute path to the deployed board in `tempdir()` (sibling of the temp daap) |
| `dev_fixtures_daap_dir` | Path to `fixtures/dp-test/` in the daapr source tree |
| `dev_fixtures_deployed_dir` | Path to `fixtures/dp_board/` in the daapr source tree |
| `daapr_fixtures_dir` | Path to the `fixtures/` directory itself |

> **Note:** After `dp_init()` returns, the active renv project has switched to
> the new temp daap. The working directory is *not* changed — callers must
> `setwd()` explicitly when needed.

### `add_test_daap_inputs(daapr_fixtures_dir)`

Copies the SDTM input files (`dm.csv`, `rs_onco_imwg.csv`) from
`fixtures/sdtm/` into `input_files/` of the current working directory (the temp
daap). Then reads the daap config, synchronises the input map against the newly
copied files, and writes the updated map back to `.daap/daap_input.yaml`.

Must be called from within the temp daap directory.

### `build_and_deploy_local_test_daap(dev_fixtures_daap_dir)`

Copies the derivation scripts (`R/derive_subjects.R`, `R/derive_bor.R`) and the
`dp_make.R` pipeline script from the fixture into the current working directory
(the temp daap), then:

1. Runs the `targets` pipeline via `targets::tar_make(script = "dp_make.R")`
2. Commits the build with `dp_commit()`
3. Deploys to the local board with `dp_deploy()`

The push step is intentionally skipped — this is a local-only test.

Must be called from within the temp daap directory.

---

## Fixture Creation (`fixtures/create_dp-test.R`)

Run this script to (re)generate the committed fixture files. It creates a fresh
daap in a `callr::r_session`, builds it end-to-end using the helpers above, and
copies a curated subset of the output into the `fixtures/` directory.

### What it does

Inside the subprocess it:

1. Calls `init_local_test_daap()` to create a fresh daap in `tempdir()`
2. `setwd()`s into the temp daap
3. Calls `dpcode_add()` to add the default journal and pipeline scripts
4. Calls `add_test_daap_inputs()` to copy SDTM files and sync the input map
5. Calls `build_and_deploy_local_test_daap()` to run the pipeline and deploy

Then saves the outputs to `fixtures/`:

- **`dp_board/`** — The entire deployed board is wiped and replaced.
  This is necessary because `pins` creates version subdirectories with
  timestamp-based names that change on every run.
- **`dp-test/`** — The daap directory is wiped and then a curated subset of
  files is copied over. Only files that should be stable across runs are
  included. Excluded: `.Rprofile`, `renv/`, git internals, `.Rproj`, and the
  `input_files/` and `output_files/` directories.

### How to run it

From your project root, with daapr loaded:

```bash
Rscript -e "pkgload::load_all(); source('tests/testthat/fixtures/create_dp-test.R')"
```

Or from an interactive R session already in the project root:

```r
pkgload::load_all()
source("tests/testthat/fixtures/create_dp-test.R")
```

### Reverting a local fixture update

See (#when-to-update-the-fixture) for more details on deciding whether 
to update the fixture.

If you ran `create_dp-test.R` to test but don't want to move forward with
your fixture changes, make sure to follow the below steps to properly revert
all fixture pin files and folders to the previous version of the fixture. This
is necessary because each new pin version will create a timestamped subdirectory 
that will need to be cleaned up. 

Don't manually delete these pin files: leaving a pin version directory in place
without its data files produces an empty (malformed) pin version that `pins`
can't read. Instead run the following commands: 

```bash
git restore tests/testthat/fixtures/    # restore deleted + modified tracked files
git clean -fd tests/testthat/fixtures/  # remove new untracked version directories
```

---

## E2E Tests (`test-e2e.R`)

The single test (`"everything works end to end"`) steps through the full daap
workflow in order and asserts correctness at each stage. It uses a single
`callr::r_session` across setup, code generation, input loading, build, and
deploy so the temp daap's active `renv` project is preserved across steps.

| Stage | What is checked |
|---|---|
| `dp_init()` | Expected files (`renv.lock`, `R/global.R`, `README.Rmd`, etc.) and directories (`input_files/`, `output_files/`) exist |
| Config | `daap_config.yaml` has the correct `project_name` and a valid `board_params_set_dried` string |
| Package version | `renv.lock` contains `daapr`, and its version matches `packageDescription("daapr")$Version` |
| `dp_init()` file contents | `R/global.R` and `README.Rmd` match the installed `inst/` copies via MD5 hash |
| Working directory | `getwd()` is restored to `starting_dir` after `dp_init()` |
| renv project | Active renv project points to the temp daap (path normalised for macOS `/var` → `/private/var` symlink) |
| `dpcode_add()` | `R/global.R` matches the fixture; `dp_journal.Rmd` matches `inst/dp_journal_targets.Rmd`; `dp_make.R` matches `inst/_targets.R` |
| `dpcode_add()` lockfile update | `renv.lock` no longer contains `drake` and does contain `targets` |
| Input ingestion | `add_test_daap_inputs()` creates `.daap/daap_input.yaml` entries for `dm` and `rs_onco_imwg`, and the deployed input pins match the fixture |
| Full build & deploy | `build_and_deploy_local_test_daap()` completes, `.daap/daap_log.yaml` contains a single non-`HEAD` `rds_log_*` entry, and the deployed output pin matches the fixture output |
| Reading deployed daap | `dpconf_get()`, `dp_connect()`, `dp_list()`, and `dp_get()` work against the local board, and the recovered input/output objects match the deployed artifacts |
| Package version consistency | The `daapr` version used in each `callr` step matches the version used to launch the test |

### `daapr` version used

* packageVersion error if not installed
* packageDescription warns + returns NA if not installed
* packageDescription + packageVersion has dev version after devtools::load_all
* packageVersion and packageDescription have consistent behavior for detecting version from loaded vs. installed version
* renv.lock RemoteSha is just the sha from the installed version from remote, so won't exist if not installed via GH
* The test we really want would need to give us a hash of the entirety of the package's currently loaded code

---

## When to Update the Fixture

Regenerate the fixture (re-run `create_dp-test.R`) whenever a code change alters
the **expected output** of a daap. Common cases:

- Changes to files in `inst/` — `global.R`, `README.Rmd`, `_targets.R`,
  `dp_journal_targets.Rmd`
- Changes to `dp_init()`, `dpcode_add()`, `dp_deploy()`, or any `dpinput_*()`
  function that affect output file contents or directory structure
- Intentional changes to `daap_config.yaml` structure or defaults
- Bumping the daapr package version that should be recorded in `renv.lock`
- Adding or removing input datasets in `fixtures/sdtm/`

> **Do not** regenerate the fixture to paper over a failing test. Investigate
> the regression first — a fixture update should be a deliberate, reviewed
> change.

If you are updating the test fixture, make sure to include the update fixture 
in your feature pull request, along with a justification for the fixture update
and details on what's changing in the fixture. 

---

## Running the E2E Tests

### As a GitHub Actions workflow

The `R-CMD-check` action runs `R CMD check`, which will include the e2e test.
The action uses whatever version of daapr is current on the branch under test.
Ensure `GITHUB_PAT` is available as a repository secret.

### Locally before a PR

Before opening a PR, make sure to check your changes using either `devtools::test()` 
or `devtools::check()`. If you want to run a subset of the test suite or a particular
test, see additional options below. 

```r
# Run all tests, including e2e
pkgload::load_all()
devtools::test()
# Run all all package checks including full test suite
devtools::check()
```

#### More e2e testing options

```r
# Run only the e2e test
testthat::test_file("tests/testthat/test-e2e.R")
# Run all tests, excluding e2e
devtools::test(filter = "e2e", invert=TRUE)
```

When using `devtools::load_all()`, `packageDescription("daapr")` will return
`NA` for `Repository` and `RemoteType`/`RemoteUrl`. Only `Version` (sourced from
`DESCRIPTION`) is reliable for the `renv.lock` version check.

If you want to run `devtools::check()` without the e2e test, use the opt-out env variable `SKIP_E2E_TEST`:

```r
withr::with_envvar(c(SKIP_E2E_TEST = "1"), devtools::check())
```

---

## Known Limitations and TODOs

- The e2e test explicitly reuses a single `callr::r_session`; cleanup of the
  temp directories is not currently done with `fs::dir_delete()` at the end of
  the test
- `dp_journal.RMD` has an uppercase `.RMD` extension in the fixture that needs
  to be fixed
- The `renv.lock` content check TODO is still limited to targeted package checks
  rather than a fuller fixture comparison
- The `.Rproj` file is only created in interactive RStudio sessions and is
  therefore excluded from the fixture
