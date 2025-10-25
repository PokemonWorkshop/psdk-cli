# PSDK CLI

## Goal

Utility cli that would help people perform several actions related to PSDK.

List of actions:

- Plugin development
- Documentation generation
- SDK release
- Static binary compilation
- Project compilation optimization
- Project data management
- Project PSDK version management
- CLI PSDK version management
- CLI Update

## Dependencies

In order to be able to work in a stand alone mode, the PSDK CLI will use its own PSDK version that will be located in ~/.psdk-cli. It'll do the same for most of the repository it will depend on.

List of dependencies:

- pokemonsdk (mandatory)
- [GameDataPacks](https://github.com/PokemonWorkshop/GameDataPacks) for data management
- [PSDKTechnicalDemo](https://github.com/PokemonWorkshop/PSDKTechnicalDemo) for data management
- [unparse](https://github.com/NuriYuri/unparse) for compilation matters
- [static-ruby-experiment](https://github.com/NuriYuri/static-ruby-experiment) for static binary compilation

PSDK CLI will also depend on known tools:

- git
- ruby
- yard-doc
- gcc
- cmake

## Action details

### Plugin development

The plugin development action is triggered with `psdk-plugin` and exposes the same arguments as the psdk plugin manager.

Note: If the command is used outside of a PSDK project, the psdk-cli will use it's own PSDK version and the additional resources will be assumed as in the plugin's folder instead of project's folder.

### Documentation generation

The documentation generation action is triggered with `psdk-doc`.

This action does the following:

1. Checkout psdk to the specified commit (or last development commit if not specified)
2. Merge the PSDK scripts by category
3. Eliminate module/class redefinition for each category
4. Remove function bodies
5. Run the yard-doc command
6. If credentials provided: publish the doc to the FTP

Some steps can be skipped:

- `psdk-doc skip_script`: skips the step 2 to 4.
- `psdk-doc skip_yard`: skips the yard step
- `psdk-doc skip_ftp`: skips the ftp step

Skips can be provided together, eg. `psdk-doc skip_script skip_yard` => uploads the existing docs

To specify the psdk commit to checkout, use the `--commit=` argument, eg. `psdk-doc --commit=deadcafe skip_ftp`

### SDK Release

The SDK Release action is triggered with `psdk-release`.

This action does the following:

1. Checkout psdk to the last development commit.
2. Merge the PSDK scripts by category
3. Eliminate module/class redefinition for each category
4. Generate the mega-deflate file
5. Bump the PSDK version (patch if not specified)
6. If credentials provided: publish the mega-deflate and release info to the FTP
7. Create a new version commit on development
8. Create a new release commit on release

Some steps can be skipped:

- `psdk-release skip_script`: skips step 2 to 4
- `psdk-release skip_bump`: skips the bump version step
- `psdk-release skip_commits`: skips the commit steps
- `psdk-release skip_ftp`: skip the ftp step

To specify how to bump the version you can use the `--bump=` argument with:

- `major` to bump the major version (.1.25.3 -> .2.0.0)
- `minor` to bump the minor version (.1.26.47 -> .1.27.0)
- `patch` to bump the patch version (.1.26.47 -> .1.26.48)

Note: PSDK uses a 32 bit unsigned integer to represent version, bumping above 255 leads to unexpected behavior.

### Static binary compilation

The Static binary compilation action allows the maker to generate a static binary with additional functionality for its project. This is all based on the [static-ruby-experiment](https://github.com/NuriYuri/static-ruby-experiment). This action is triggered with `psdk-static` and is platform dependent.

Note: as of now, this action will not be developed.

### Project compilation optimization

The project compilation optimization is triggered with `psdk-compile` and allow the maker to perform additional compilation optimizations using plugins that would be in `<project_dir>/plugins` and that would be loaded via arguments.

Eg. `psdk-compile --with=custom_yuki_vd_encryption --with=custom_image_format` will start the project compilation after loading `<project_dir>/plugins/custom_yuki_vd_encryption.rb` and `<project_dir>/plugins/custom_image_format`

This command accepts all the skips from the og project compilation command.

### Project data management

The Project data management action is triggered with `psdk-data`. It has several sub actions.

#### Data pack installation

The data pack installation is triggered with `psdk-data pack add <generation>` where generation is the generation to install; demo will use the [PSDKTechnicalDemo](https://github.com/PokemonWorkshop/PSDKTechnicalDemo) as source of data.

You can also update the data pack installation with `psdk-data pack update <generation>`.

#### Git Synchronization

To ensure the data is correctly synchronized with data pull via git, you can use `psdk-data sync`. This command will force regenerate the `psdk.dat` file.

(TODO: think how we can deal with tiled map synchronization between people)

#### Conflict management

When using data pack or demo pack, you might have conflicts here's all the arguments to deal with conflicts:

- `--source-of-truth=<generation>` : specify the source of truth for checking file SHA-1
- `--source-of-truth-commit=<commit>` : specify the commit to use in order to compare file SHA-1
- `--remove-extra=<type>` : tell the command to remove extra files of a type (eg. `--remove-extra=dex` will remove all the extra dex)
- `--overwrite=<type>` : tell the command to overwrite all the files of a type without comparison. If type is all, it'll overwrite all the data.

Note: if no conflict management is specified, the command will work in `--overwrite=all` mode.

TODO: check all scenarios and redefine conflict management

### Project PSDK version management

The Project PSDK version management action is triggered with `psdk-use`.

Here's all the variations of `psdk-use`

- `psdk-use studio` Use the Pokémon Studio PSDK version
- `psdk-use studio delete` Use the Pokémon Studio PSDK version and delete recursively the pokemonsdk folder (instead of renaming it .pokemonsdk)
- `psdk-use version <id>` Use a specific PSDK version
- `psdk-use commit <id>` Use a specific PSDK commit
- `psdk-use mr <id>` Use a specific PSDK based on the Merge Request ID or Merge Request URL
- `psdk-use latest` Use the last PSDK commit from development

### CLI PSDK version management

By default the CLI always use the last commit of development for plugin management or project compilation. If you need to use a different commit or PSDK version, you can use `psdk-cli-use` to specify the version to use. It works like `psdk-use` but without the studio version.

### CLI Update

To update the CLI, you can run the command `psdk-cli update`, it will fetch and install the updates for the psdk cli tool.

## Q & A

> How do we use the PSDK's ruby version with the CLI?

The PSDK CLI is stand alone, the only time it'll use the Ruby version from PSDK will be during the project compilation (so LiteRGSS can be used and Ruby scripts can be compiled to target version).

> How do we install the CLI?

The PSDK CLI will be install using Ruby Gems, this makes the process easier for everyone.

> What do we do with PSDK's tools as they may do similar things as PSDK-CLI?

Most of the PSDK tools are for in-game debugging but some of them will be split between CLI and Tools. For example, creating a plugin will be in PSDK CLI exclusively, loading all the plugins will be in PSDK tools exclusively.

> Shall we use [Thor](https://github.com/rails/thor) to implement PSDK-CLI?

Yes, let's go with that.

> Will we be forced to use the FTP for the SDK Release action?

As soon as all the tools around PSDK are able to fetch PSDK updates from gitlab releases, we can remove the FTP step from SDK Release action. Regarding the docs, we have to keep using FTP to send it the the website.
