# Package index

## Credential functions

- [`board_params_set_labkey()`](https://daapr-team.github.io/daapr/reference/board_params_set_labkey.md)
  : Create formatted parameters that specify a LabKey board
- [`board_params_set_local()`](https://daapr-team.github.io/daapr/reference/board_params_set_local.md)
  : Create formatted parameters that specify a local storage board
- [`board_params_set_s3()`](https://daapr-team.github.io/daapr/reference/board_params_set_s3.md)
  : Create formatted parameters that specify an s3 bucket board
- [`creds_set_aws()`](https://daapr-team.github.io/daapr/reference/creds_set_aws.md)
  : Create formatted credentials for connecting to an s3 bucket board
- [`creds_set_labkey()`](https://daapr-team.github.io/daapr/reference/creds_set_labkey.md)
  : Create formatted credentials for connecting to a LabKey board

## Data product core functions

- [`dp_activate()`](https://daapr-team.github.io/daapr/reference/dp_activate.md)
  : Activate data product project
- [`dp_clone()`](https://daapr-team.github.io/daapr/reference/dp_clone.md)
  : Clone data product project from a remote repo
- [`dp_commit()`](https://daapr-team.github.io/daapr/reference/dp_commit.md)
  : Commit data product
- [`dp_connect()`](https://daapr-team.github.io/daapr/reference/dp_connect.md)
  : Connect to the data product pin board
- [`dp_deploy()`](https://daapr-team.github.io/daapr/reference/dp_deploy.md)
  : Deploy data product
- [`dp_get()`](https://daapr-team.github.io/daapr/reference/dp_get.md) :
  Get the data product from the remote pin board
- [`dp_init()`](https://daapr-team.github.io/daapr/reference/dp_init.md)
  : Initialize data product project
- [`dp_list()`](https://daapr-team.github.io/daapr/reference/dp_list.md)
  : List data products on a remote pin board
- [`dp_make_params()`](https://daapr-team.github.io/daapr/reference/dp_make_params.md)
  : Make dp params to connect to the Data Product Board
- [`dp_pull()`](https://daapr-team.github.io/daapr/reference/dp_pull.md)
  : Pull data product from a remote repo
- [`dp_push()`](https://daapr-team.github.io/daapr/reference/dp_push.md)
  : Push data product to remote repo
- [`dp_structure()`](https://daapr-team.github.io/daapr/reference/dp_structure.md)
  : Structure a data product
- [`dp_tolink()`](https://daapr-team.github.io/daapr/reference/dp_tolink.md)
  : Converts a data product to a link
- [`dp_write()`](https://daapr-team.github.io/daapr/reference/dp_write.md)
  : Write data product

## Config functions

- [`dpconf_get()`](https://daapr-team.github.io/daapr/reference/dpconf_get.md)
  : Get data product config information
- [`dpconf_update()`](https://daapr-team.github.io/daapr/reference/dpconf_update.md)
  : Modify data product configuration

## Input functions

- [`dpinput_map()`](https://daapr-team.github.io/daapr/reference/dpinput_map.md)
  : Map data input into data product workflow
- [`dpinput_read()`](https://daapr-team.github.io/daapr/reference/dpinput_read.md)
  : Read data product input manifest
- [`dpinput_sync()`](https://daapr-team.github.io/daapr/reference/dpinput_sync.md)
  : Sync Input Data to Remote
- [`dpinput_syncflag_reset()`](https://daapr-team.github.io/daapr/reference/dpinput_syncflag_reset.md)
  : Reset sync flag in the manifest
- [`dpinput_write()`](https://daapr-team.github.io/daapr/reference/dpinput_write.md)
  : Write data product input manifest
- [`inputmap_clean()`](https://daapr-team.github.io/daapr/reference/inputmap_clean.md)
  : Clean input_map

## Helper data product functions

- [`dpcode_add()`](https://daapr-team.github.io/daapr/reference/dpcode_add.md)
  : Adds script templates
- [`dpname_get()`](https://daapr-team.github.io/daapr/reference/dpname_get.md)
  : Get Data Product Name
- [`dpname_make()`](https://daapr-team.github.io/daapr/reference/dpname_make.md)
  : Make Data Product Name
- [`readme_get()`](https://daapr-team.github.io/daapr/reference/readme_get.md)
  : Get Readme to be appended to the data object

## Auxillary functions

- [`dppkg_modify()`](https://daapr-team.github.io/daapr/reference/dppkg_modify.md)
  : R package version update
- [`fn_dry()`](https://daapr-team.github.io/daapr/reference/fn_dry.md) :
  Dry a called function
- [`is_valid_dp_repository()`](https://daapr-team.github.io/daapr/reference/is_valid_dp_repository.md)
  : Determine if valid dp repository
- [`make_names_codefriendly()`](https://daapr-team.github.io/daapr/reference/make_names_codefriendly.md)
  : Make names code friendly
- [`tbsig_get()`](https://daapr-team.github.io/daapr/reference/tbsig_get.md)
  : Get sha1 signature for a table
