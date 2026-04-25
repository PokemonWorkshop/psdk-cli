## Story

Source: [Github Issue #10](https://github.com/PokemonWorkshop/psdk-cli/issues/10)

### Description

As a developer, I want to use `psdk-plugin` to manage my PSDK plugins (create, test, update) to simplify maintenance.

> [!NOTE]
> We'll remove the plugin command from PSDK (aside the one for loading the plugin) and psdk cli will be responsible of plugin management (including build).
> It'll accept both workflow:
> - Plugin inside a PSDK project (meaning the resources are expected to be at the root of the project and scripts at the root of the plugin)
> - Plugin outside a PSDK project (meaning both resources and scripts are expected to be at the root of the plugin)
> The definition file remain the same for both workflow  

### Acceptance criteria

- [ ] `psdk-plugin` exposes the same arguments as the original plugin manager.
- [ ] The command detects the project or switches to standalone mode.
- [ ] A clear message lists available actions (list, build).

## Information about `PluginManager.rb`

This file depends on Yuki::VD (defined in `lib/psdk/helpers/900 Yuki__VD.rb`)

This file was taken out of Pokémon SDK and currently is only working in the context of a PSDK project.

In the psdk-cli I want the following commands:

- `PluginManager.start(:build, 'plugin_name')`
- `PluginManager.start(:list)`

The `PluginManager.start(:load)` should never work in the psdk-cli as it's supposed to run in a game not in the CLI.

Currently, the build process expects the following structure:

- `scripts/{plugin_name}/config.yml` (plugin configuration file)
- `scripts/{plugin_name}/script/**/*.rb` (scripts, automatic)
- `graphics/**/*.*` (added_file)
- `Data/**/*.*` (added_files)
- `audio/**/*.*` (added_files)

I want this process to be preserved if psdk-cli is running in a PSDK project (`Configuration.project_path != nil`). And if I'm not in a project (or a --no-psdk-project flag is set). I want the following structure so developing plugins is easier:

- `config.yml` (plugin configuration file)
- `scripts/**/*.rb` (scripts, automatic)
- `graphics/**/*.*` (added_file)
- `Data/**/*.*` (added_files)
- `audio/**/*.*` (added_files)

In this structure, it's assumed that we are inside `{plugin_name}` (if we use `.` as plugin directory we should skip the plugin_name argument of `PluginManager.start(:build)` since the name is also inside `config.yml`)

## Task to perform

1. Explode `PluginManager.rb` in several ruby scripts that are able to perform the following operations:
   - `list` all the plugins of current project (should fail if not in a project)
   - `build` a plugin (name is optional, if not provided and not in a project, it's `.`)
2. Rewrite the Build command so it's
   1. Verbose (explaining each stuff it does and where it is)
   2. Able to work outside of a psdk project (should also state it's not in a PSDK project)
3. Move the exploded PluginManager files to `lib/psdk/helpers/plugin-manager`
4. Write a script in `lib/psdk/cli` to expose the `psdk-cli plugin` cli commands
5. Write a `psdk-plugin` file in `exe` (so I can run `psdk-plugin` instead of `psdk-cli plugin`)
6. Write unit tests in `spec` for Exploded PluginManager files
7. Write unit tests in `spec` for the `psdk-cli plugin` commands
