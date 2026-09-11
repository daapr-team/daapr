# Read Pin from Board (internal)

Internal wrapper function that reads a pin from a board object.
Automatically selects the appropriate pin_read function based on the
board type (LabKey vs. standard pins).

## Usage

``` r
read_pin_from_board(board_object, data_name, version = NULL)
```

## Arguments

- board_object:

  A `pins_board` object from `dp_connect`. Can be a folder board, LabKey
  board, or S3 board.

- data_name:

  The name of the data product to read.

- version:

  The version of the pin to read. If `NULL`, reads the latest version
  available.

## Value

The data product object read from the pin board.
