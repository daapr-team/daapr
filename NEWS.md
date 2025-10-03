# daapr 0.2.0

* Add back support for LabKey boards. `pinsLabkey` is now required to work with LabKey boards

# daapr 0.1.0

## Breaking changes

* daapr now requires pins >= v1.2.0 and dpi, dpbuild, dpdeploy packages have been updated accordingly. The daapr dependencies have been update to reflect these changes. 
* Forwards incompatibility: older data products build with custom/legacy pins are incompatible with daapr >= 0.1.0.
* LabKey functionality has been temporarily removed until pins v1 can be extended to support LabKey boards

## Other improvments

* Added a `NEWS.md` file to track changes to the package.

--------

# daapr 0.0.0

### dpbuild 0.2.1

* Make targets default when using `dpcode_add()` as drake is superseded (#90)
* Address #95 to allow `dpconf_get()` to be called outside of project directory
* Fixed windows bug related to `file.path()` call in `dp_connect()`

## dpbuild 0.2.0

* Added back support for LabKey boards (#86). `pinsLabkey` is now required to work with LabKey boards
* Update default gitignore used in `dp_init()` to include .RData as well as other common files (#84).

## dpbuild 0.1.0

### Breaking changes

* dpbuild now requires pins >= v1.2.0. This means that data products will now use the v1 api and older data products are incompatible with dpbuild >= 0.1.0. Quite a few changes under the hood, but users will see minimal changes to the workflow.
* LabKey functionality has been temporarily removed until pins v1 can be extended to support LabKey boards

### Other improvments

* Added a `NEWS.md` file to track changes to the package.

-----------------

## dpi 0.3.0

* Fully deprecated `board_alias` (#42) argument, which is deprecated in `pinsLabkey` v0.2.0
* Addressed `dp_connect` issue on on windows related to removed of trailing slashes in s3 dirs (#38)

## dpi 0.2.0

* Added back support for LabKey boards (#32). `pinsLabkey` is now a dependency. 
* When working with s3 boards, `dp_connect()` now throws an error if `paws.labkey` is not installed (#33).

## dpi 0.1.1

* Fixed issue #29 where `dp_get()` could not pull old pin versions by hash. Now using hash to look up version number to pass to `pin_read()`
* Fixed typos in downgrade messages

## dpi 0.1.0

### Breaking changes

* dpbuild now requires pins >= v1.2.0. This means that data products will now use the v1 api and older data products are incompatible with dpbuild >= 0.1.0. Quite a few changes under the hood, but users will see minimal changes to the workflow.
* LabKey functionality has been temporarily removed until pins v1 can be extended to support LabKey boards
* data products are now retrieved by pin hash, rather than version. Since pins v1 pin version has included both hash and datetime stamp, but `dp_get` retrieves data products using hash only. 

### Other improvments

* Added a `NEWS.md` file to track changes to the package.
* `board_params_set_s3` no longer requires a board_alias
* `dp_connect` returns a board object that can be passed to `dp_get`, `dp_list`
* `dpconnect_check` removed to streamline workflow

-----------

## dpdeploy 0.3.0

* Removed references to `board_alias` (#34) as this argument is now deprecated with `pinsLabkey` v0.2.0
* Addressed `dp_connect` issue on on windows related to removed of trailing slashes in s3 dirs

## dpdeploy 0.2.0

* Add back support for LabKey boards (#29). `pinsLabkey` is now required to work with LabKey boards

## dpdeploy 0.1.0

### Breaking changes

* dpdeploy now requires pins >= v1.2.0. This means that data products will now use the v1 api and older data products are incompatible with dpdeploy >= 0.1.0. Quite a few changes under the hood, but users will see minimal changes to the workflow. 
* LabKey functionality has been temporarily removed until pins v1 can be extended to support LabKey boards
* data products are now retrieved by pin hash, rather than version. Since pins v1 pin version has included both hash and datetime stamp. 

### Other improvments

* Added a `NEWS.md` file to track changes to the package.
* `dpconnect_check` removed to streamline workflow
