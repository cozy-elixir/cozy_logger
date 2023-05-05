# CozyLogger

> Logging helpers, providing various formatters and seamless integrations with other libraries.

## Features

- Formatters
  - [x] JSON Formatter
  - ...
- Integrations
  - [x] Phoenix
  - [ ] Ecto
  - ...

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `cozy_logger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cozy_logger, "~> 0.1.0"}
  ]
end
```

## About the design

- The **formatters** are only responsible for formatting, they do not handle any vendor-specific formats.
- The **integrations** process telemetry events to print logs, and provide `install/0` or `install/1` functions for convenient initialization.

## License

Apache License 2.0
