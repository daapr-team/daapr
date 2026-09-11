# Add readme to the project

Add readme to the project

## Usage

``` r
add_readme(
  project_path,
  dp_title,
  github_repo_url,
  board_params_set_dried,
  creds_set_dried
)
```

## Arguments

- project_path:

  Path to the project folder

- dp_title:

  readme title

- github_repo_url:

  github repo url

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
