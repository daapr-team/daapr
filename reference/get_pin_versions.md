# Get Pin Versions from Board (internal)

Internal wrapper function that retrieves pin versions from a board
object. Automatically selects the appropriate pin_versions function
based on the board type (LabKey vs. standard pins).

## Usage

``` r
get_pin_versions(board_object, data_name)
```

## Arguments

- board_object:

  A `pins_board` object from `dp_connect`. Can be a folder board, LabKey
  board, or S3 board.

- data_name:

  The name of the data product to get versions for.

## Value

A data frame containing version information with columns for hash,
version, and other metadata depending on the board type.
