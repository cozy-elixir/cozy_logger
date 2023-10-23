# CozyLogger

[![built with Nix](https://img.shields.io/badge/built%20with%20Nix-5277C3?logo=nixos&logoColor=white)](https://builtwithnix.org)
[![CI](https://github.com/cozy-elixir/cozy_logger/actions/workflows/ci.yml/badge.svg)](https://github.com/cozy-elixir/cozy_logger/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/cozy_logger.svg)](https://hex.pm/packages/cozy_logger)

<!-- MDOC -->

Logging helpers, providing format functions of various formats and seamless integrations with other libraries.

## Features

- Formats
  - [x] JSON
  - ...
- Integrations
  - [x] Phoenix
  - [ ] Ecto
  - ...

## Installation

[Install it from Hex](https://hex.pm/packages/cozy_logger).

## Usage

For more information, see the [documentation](https://hexdocs.pm/cozy_logger).

## About the design

- The **formats** are only responsible for formatting, they do not handle any vendor-specific formats.
- The **integrations** process telemetry events to print logs, and provide `install/0` or `install/1` functions for convenient initialization.

## License

Apache License 2.0
