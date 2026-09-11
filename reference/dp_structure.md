# Structure a data product

This function assembles the data product and properly assigns class and
attributes. For examples, use `dpcode_add` to generate a dp_make.R file

## Usage

``` r
dp_structure(data_files_read, config, output = list(), metadata = list())
```

## Arguments

- data_files_read:

  object generated from
  [`dpinput_read()`](https://daapr-team.github.io/daapr/reference/dpinput_read.md)
  containing links to input data

- config:

  data product config file from `dpconf_get`

- output:

  a list of content to be structured under output

- metadata:

  a list of content to be structured under metadata

## Value

a list containing README, raw_input, input, and output
