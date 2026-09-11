# Check if Board References Data Product Input (internal)

Internal helper function that determines whether a pins board object is
configured to reference a data product input folder (dpinput) based on
the board type and its path configuration.

## Usage

``` r
is_dpinput_board(board_object)
```

## Arguments

- board_object:

  A `pins_board` object from `dp_connect`. Can be a local board, LabKey
  board, or S3 board.

## Value

Logical value: `TRUE` if the board references a data product input
folder, `FALSE` if it references a regular data product folder.

## Details

The function examines the board's path configuration:

- For `pins_board_folder`: checks the `path` attribute

- For `pins_board_labkey`: checks the `subdir` attribute

- For `pins_board_s3` boards: checks the `prefix` attribute

It splits the path by underscores, hyphens, and slashes, then checks if
the last component equals "dpinput".
