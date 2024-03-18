defmodule TypedStructDataFrameTestMessage do
  use TypedStruct

  typedstruct do
    plugin(TypedStructDataFrame)

    field(:string_field, :string)
    field(:binary_field, :binary)
    field(:boolean_field, :boolean)
    field(:integer_field, :integer)
    field(:float_field, :float)
    field(:decimal_field, :decimal)
    field(:money_field, Money.Ecto.Amount.Type)
    field(:date_field, :date)
    field(:time_field, :time)
    field(:datetime_field, :naive_datetime)
  end
end

defmodule TypedStructDataFrameTest do
  use ExUnit.Case, async: true

  require Explorer.DataFrame, as: DF

  setup_all do
    Application.put_env(:money, :default_currency, :USD)
    :ok
  end

  describe "dtypes/0" do
    test "creates the correct dtypes for each field type" do
      assert TypedStructDataFrameTestMessage.dtypes() == [
               string_field: :string,
               binary_field: :binary,
               boolean_field: :boolean,
               integer_field: :integer,
               float_field: :float,
               decimal_field: :float,
               money_field: :float,
               date_field: :date,
               time_field: :time,
               datetime_field: {:datetime, :millisecond}
             ]
    end
  end

  describe "empty_df/0" do
    test "creates the correct empty dataframe" do
      empty_df = TypedStructDataFrameTestMessage.empty_df()

      expected_dtypes =
        TypedStructDataFrameTestMessage.dtypes()
        |> Enum.map(fn {field, value} -> {Atom.to_string(field), value} end)
        |> Enum.into(%{})

      assert DF.to_rows(empty_df) == []
      assert DF.dtypes(empty_df) == expected_dtypes
    end
  end

  describe "from_dataframe/1" do
    test "properly parses a dataframe into a list of structs" do
      df =
        DF.new(
          %{
            string_field: ["string1", "string2"],
            binary_field: ["binary1", "binary2"],
            boolean_field: [true, false],
            integer_field: [1, 2],
            float_field: [1.0, 2.0],
            decimal_field: [1.0, 2.0],
            money_field: [1.00, 2.00],
            date_field: [~D[2020-01-01], ~D[2021-01-01]],
            time_field: [~T[00:00:00], ~T[01:00:00]],
            datetime_field: [~N[2020-01-01 00:00:00], ~N[2021-01-01 00:00:00]]
          },
          dtypes: TypedStructDataFrameTestMessage.dtypes()
        )

      assert TypedStructDataFrameTestMessage.from_dataframe(df) == [
               %TypedStructDataFrameTestMessage{
                 time_field: ~T[00:00:00.000000],
                 date_field: ~D[2020-01-01],
                 datetime_field: ~N[2020-01-01 00:00:00.000000],
                 money_field: %Money{amount: 100, currency: :USD},
                 decimal_field: Decimal.new("1.0"),
                 float_field: 1.0,
                 integer_field: 1,
                 boolean_field: true,
                 binary_field: "binary1",
                 string_field: "string1"
               },
               %TypedStructDataFrameTestMessage{
                 time_field: ~T[01:00:00.000000],
                 date_field: ~D[2021-01-01],
                 datetime_field: ~N[2021-01-01 00:00:00.000000],
                 money_field: %Money{amount: 200, currency: :USD},
                 decimal_field: Decimal.new("2.0"),
                 float_field: 2.0,
                 integer_field: 2,
                 boolean_field: false,
                 binary_field: "binary2",
                 string_field: "string2"
               }
             ]
    end
  end

  describe "to_dataframe/1" do
    test "properly parses a struct into a single row dataframe" do
      struct =
        %TypedStructDataFrameTestMessage{
          time_field: ~T[00:00:00],
          date_field: ~D[2020-01-01],
          datetime_field: ~N[2020-01-01 00:00:00],
          money_field: %Money{amount: 100, currency: :USD},
          decimal_field: Decimal.from_float(1.0),
          float_field: 1.0,
          integer_field: 1,
          boolean_field: true,
          binary_field: "binary1",
          string_field: "string1"
        }

      received_df = struct |> TypedStructDataFrameTestMessage.to_dataframe() |> DF.to_rows()

      assert received_df == [
               %{
                 "time_field" => ~T[00:00:00.000000],
                 "date_field" => ~D[2020-01-01],
                 "datetime_field" => ~N[2020-01-01 00:00:00.000000],
                 "money_field" => 1.00,
                 "decimal_field" => 1.0,
                 "float_field" => 1.0,
                 "integer_field" => 1,
                 "boolean_field" => true,
                 "binary_field" => "binary1",
                 "string_field" => "string1"
               }
             ]
    end

    test "properly parses a list of structs to a dataframe" do
      structs = [
        %TypedStructDataFrameTestMessage{
          time_field: ~T[00:00:00],
          date_field: ~D[2020-01-01],
          datetime_field: ~N[2020-01-01 00:00:00],
          money_field: %Money{amount: 100, currency: :USD},
          decimal_field: Decimal.from_float(1.0),
          float_field: 1.0,
          integer_field: 1,
          boolean_field: true,
          binary_field: "binary1",
          string_field: "string1"
        },
        %TypedStructDataFrameTestMessage{
          time_field: ~T[01:00:00],
          date_field: ~D[2021-01-01],
          datetime_field: ~N[2021-01-01 00:00:00],
          money_field: %Money{amount: 200, currency: :USD},
          decimal_field: Decimal.from_float(2.0),
          float_field: 2.0,
          integer_field: 2,
          boolean_field: false,
          binary_field: "binary2",
          string_field: "string2"
        }
      ]

      received_df = TypedStructDataFrameTestMessage.to_dataframe(structs) |> DF.to_rows()

      assert received_df == [
               %{
                 "time_field" => ~T[00:00:00.000000],
                 "date_field" => ~D[2020-01-01],
                 "datetime_field" => ~N[2020-01-01 00:00:00.000000],
                 "money_field" => 1.00,
                 "decimal_field" => 1.0,
                 "float_field" => 1.0,
                 "integer_field" => 1,
                 "boolean_field" => true,
                 "binary_field" => "binary1",
                 "string_field" => "string1"
               },
               %{
                 "time_field" => ~T[01:00:00.000000],
                 "date_field" => ~D[2021-01-01],
                 "datetime_field" => ~N[2021-01-01 00:00:00.000000],
                 "money_field" => 2.00,
                 "decimal_field" => 2.0,
                 "float_field" => 2.0,
                 "integer_field" => 2,
                 "boolean_field" => false,
                 "binary_field" => "binary2",
                 "string_field" => "string2"
               }
             ]
    end
  end
end
