# TypedStructDataFrame

TypedStructDataFrame is a plugin library for the [TypedStruct](https://github.com/ejpcmac/typed_struct) library

## Rationale

Explorer.DataFrames are a powerful way to manipulate large datasets, this library provides a quick and easy way to take these DataFrames and convert them to a type safe struct(s) or vice versa.

Comes installed with Money and Decimal packages to support the Money types and Decimal types. See example below

## TODO

- [ ] Add support for abstract types to be defined by user of library
- [ ] Add support for latest Explorer.DataFrame version

## Installation

To use TypedStructDataFrame in your project, add this to your Mix dependencies:

```elixir
  {:typed_struct_data_frame, "~> 0.1.0"}
```

and then use this by adding this plugin to any TypedStruct

```elixir
  plugin(TypedStructDataFrame)
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/typed_struct_data_frame>.

## Example

```elixir
  defmodule PersonProfile do
    use TypedStruct

    typedstruct do
      plugin(TypedStructDataFrame)

        field :name, :string
        field :age, :integer
        field :is_developer, :boolean
        field :score, :decimal
        field :net_worth, Money.Ecto.Amount.Type
    end
  end
```
