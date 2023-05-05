# CozyLogger

<!-- MDOC -->

Logging helpers, providing various formatters and seamless integrations with other libraries.

## Features

- Formatters
  - [x] JSON Formatter
  - ...
- Integrations
  - [x] Phoenix
  - [ ] Ecto
  - ...

## Installation

Add `package_name` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cozy_logger, "~> <version>"}
  ]
end
```

## Usage

For more information, see the [documentation](https://hexdocs.pm/cozy_logger).

## About the design

- The **formatters** are only responsible for formatting, they do not handle any vendor-specific formats.
- The **integrations** process telemetry events to print logs, and provide `install/0` or `install/1` functions for convenient initialization.

## License

Apache License 2.0
