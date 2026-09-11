# daapr 1.0.0

First release of the combined daapr. The `dpi`, `dpbuild`, and `dpdeploy`
packages have been merged into daapr itself, so daapr is now a single
self-contained package rather than a wrapper around three others.

## Breaking changes

* **daapr is now a single package.** `dpi`, `dpbuild`, and `dpdeploy` have been
  merged into daapr and removed as dependencies. Everything they exported is now
  exported directly from daapr, so `library(daapr)` is all that is needed —
  attaching or installing the three component packages is no longer required and
  they will no longer be kept up to date. Code that calls `dpi::`, `dpbuild::`,
  or `dpdeploy::` must be updated to call `daapr::` instead.
* **R >= 4.1 is now required.** The codebase uses the native pipe (`|>`) throughout.
* **qs support has been removed.** Data objects are written and read as RDS
  only, and `qs` is no longer a dependency. `dp_write(type = "qs")` is no longer
  accepted, and existing data products whose object lives in
  `output_files/qs_format/` will not deploy or commit until they are rebuilt in
  RDS format.

## New features

* `board_params_set_s3()` gains a `prefix` argument, so data products can be
  stored under a prefix within a bucket rather than only at the bucket root.

## Bug fixes

* S3 boards configured without a `prefix` no longer have a literal `"NA"` pasted
  into the board path in `dp_connect()`, `dp_deploy()`, and `dpinput_sync()`.
* `dpcode_add()` now commits the targets `dp_journal` correctly.
* Fixed data object reading in `dp_write()`.
* Fixed several paths broken by the `.RMD` to `.Rmd` extension change in
  `dp_init()` and `dpcode_add()`.

## Other improvements

* Added an end-to-end test suite that initialises, builds, and deploys a
  `dp-test` fixture data product. It can be opted out of with the
  `SKIP_E2E_TEST` environment variable.

# daapr 0.2.0

* Add back support for LabKey boards. `pinsLabkey` is now required to work with LabKey boards

# daapr 0.1.0

## Breaking changes

* daapr now requires pins >= v1.2.0 and dpi, dpbuild, dpdeploy packages have been updated accordingly. The daapr dependencies have been update to reflect these changes. 
* Forwards incompatibility: older data products build with custom/legacy pins are incompatible with daapr >= 0.1.0.
* LabKey functionality has been temporarily removed until pins v1 can be extended to support LabKey boards

## Other improvments

* Added a `NEWS.md` file to track changes to the package.
