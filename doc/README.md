# Contributing to the Nixpkgs manual

This directory houses the source files for the Nixpkgs manual.

There are [Unstable (from master)](https://nixos.org/manual/nixpkgs/unstable/) and [Stable (from latest release)](https://nixos.org/manual/nixpkgs/stable/) renderings.

> [!NOTE]
>
> We are actively restructuring our documentation to be more beginner friendly.
>

## Style and conventions

Consult the [style guide](./styleguide.md) for guidance on writing documentation.

Follow Nixpkgs' [commit conventions](https://github.com/NixOS/nixpkgs?tab=contributing-ov-file#commit-conventions).

Documentation about Nixpkgs belongs here.
This includes getting started guides and onboarding guides for *using* Nixpkgs and the language frameworks it ships.

## Building and navigating documentation locally

The Nixpkgs manual is rendered by [nixos-render-docs](https://github.com/nixos/nixpkgs/tree/master/pkgs/by-name/ni/nixos-render-docs/) (sometimes abbreviated `nrd`) and its index is the `./nav.json` file.

### Development environment

Consider using the tooling in the documentation development environment.

Within `/path/to/nixpkgs/doc`, run `nix-shell`.

### Live preview

Run [`devmode`](../pkgs/by-name/de/devmode/README.md) for a live preview while editing the manual.

Changes to the renderer `pkgs/by-name/ni/nixos-render-docs` need a manual restart: run `devmode` again.

### Building the docs

To build the documentation, run `nix-build doc`. If it succeeds, the manual will be in `./result/share/doc/nixpkgs/manual.html`.

### Testing redirects

Once you have a successful build, you can open the relevant HTML (path mentioned above) in a browser along with the anchor, and observe the redirection.

Note that if you already loaded the page and *then* input the anchor, you will need to perform a reload. This is because browsers do not re-run client JS code when only the anchor has changed.

## Getting help

If you need documentation-specific help or reviews, ping [@NixOS/documentation-team](https://github.com/orgs/nixos/teams/documentation-team) on your pull request.
