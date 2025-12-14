#!/usr/bin/env bash

# Build the project
nix build

# Build and run
nix run

# Enter development shell
nix develop

# Run tests
nix flake check

