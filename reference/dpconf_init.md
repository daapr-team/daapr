# Initialize daap configuration file

Initializes daap configuration file `.daap/daap_config.yaml`

## Usage

``` r
dpconf_init(
  project_path,
  project_name,
  project_description = character(0),
  branch_name,
  branch_description = character(0),
  readme_general_note = character(0),
  board_params_set_dried,
  creds_set_dried,
  is_legacy,
  ...
)
```

## Arguments

- project_path:

  path to the project folder

- project_name:

  the name of the project. This is typically the name of the folder
  where the project is set

- project_description:

  A high level description of the project. Example: integrated, clinical
  and translational data from study x.

- branch_name:

  An abbreviation to capture the specific reason for which data was
  processed. Example m3cut (as in month 3 data cut)

- branch_description:

  A high level description of the branch

- readme_general_note:

  Optional general note which will be added as metadata to the data
  object

- board_params_set_dried:

  Character representation of the function for setting board_params. Use
  [`fn_dry()`](https://daapr-team.github.io/daapr/reference/fn_dry.md)
  in combination with
  [`board_params_set_s3()`](https://daapr-team.github.io/daapr/reference/board_params_set_s3.md),
  [`board_params_set_labkey()`](https://daapr-team.github.io/daapr/reference/board_params_set_labkey.md),
  or
  [`board_params_set_local()`](https://daapr-team.github.io/daapr/reference/board_params_set_local.md).

- creds_set_dried:

  Character representation of the function for setting creds. Use
  [`fn_dry()`](https://daapr-team.github.io/daapr/reference/fn_dry.md)
  in combination with
  [`creds_set_aws()`](https://daapr-team.github.io/daapr/reference/creds_set_aws.md)
  or
  [`creds_set_labkey()`](https://daapr-team.github.io/daapr/reference/creds_set_labkey.md).

- is_legacy:

  if pins version is a legacy one (Boolean)

- ...:

  any other metadata to be captured in the config file

## Value

dpconf
