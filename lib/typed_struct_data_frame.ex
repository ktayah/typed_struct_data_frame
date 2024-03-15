defmodule TypedStructDataFrame do
  use TypedStruct.Plugin

  alias Belay.ToDecimal
  alias Belay.ToMoney
  alias Explorer.DataFrame, as: DF

  @to_df_conversion_mapping %{
    Money.Ecto.Amount.Type => :float,
    # TODO: Nice to have feature, problematic to implement
    # Ecto.Enum => :category,
    :decimal => :float,
    :float => :float,
    :integer => :integer,
    :string => :string,
    :binary => :binary,
    :boolean => :boolean,
    :date => :date,
    :time => :time,
    :datetime => {:datetime, :millisecond},
    :naive_datetime => {:datetime, :millisecond},
    :naive_datetime_usec => {:datetime, :millisecond},
    :utc_datetime => {:datetime, :millisecond},
    :utc_datetime_usec => {:datetime, :millisecond}
  }

  @impl true
  defmacro init(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :dtypes, accumulate: true)
      Module.register_attribute(__MODULE__, :money_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :decimal_fields, accumulate: true)
    end
  end

  @impl true
  def field(name, type, _opts, _env) do
    quote location: :keep, bind_quoted: [name: name, type: type] do
      case type do
        Money.Ecto.Amount.Type -> Module.put_attribute(__MODULE__, :money_fields, name)
        :decimal -> Module.put_attribute(__MODULE__, :decimal_fields, name)
        _ -> nil
      end

      Module.put_attribute(__MODULE__, :dtypes, {name, TypedStructDataFrame.to_df_type(type)})
    end
  end

  @impl true
  def after_definition(_opts) do
    quote do
      @spec from_dataframe(DF.t()) :: [__MODULE__.t()]
      def from_dataframe(df) do
        if not function_exported?(__MODULE__, :new!, 1) do
          raise "Could not detect TypedStructDefNew plugin being utilized, #{__MODULE__}.from_dataframe/1 requires TypedStructDefNew plugin"
        end

        df
        |> DF.to_rows()
        |> Enum.map(fn df_row ->
          df_row
          |> TypedStructDataFrame.convert_df_row_fields(@money_fields, &ToMoney.to_money/1)
          |> TypedStructDataFrame.convert_df_row_fields(@decimal_fields, &ToDecimal.to_decimal/1)
          |> __MODULE__.new!()
        end)
      end

      @spec to_dataframe(__MODULE__.t() | [__MODULE__.t()]) :: DF.t()
      def to_dataframe([]), do: empty_df()

      def to_dataframe(%__MODULE__{} = struct) do
        to_dataframe([struct])
      end

      def to_dataframe(structs) when is_list(structs) do
        structs
        |> Enum.map(fn struct ->
          struct
          |> Map.from_struct()
          |> TypedStructDataFrame.convert_struct_fields(@money_fields, fn money ->
            money.amount / 100
          end)
          |> TypedStructDataFrame.convert_struct_fields(@decimal_fields, &Decimal.to_float/1)
        end)
        |> DF.new(dtypes: @dtypes)
      end

      @spec dtypes() :: list()
      def dtypes(), do: Enum.reverse(@dtypes)

      @spec empty_df() :: DF.t()
      def empty_df() do
        @dtypes
        |> Enum.map(fn {name, _dtype} -> {name, []} end)
        |> Enum.reverse()
        |> DF.new(dtypes: @dtypes)
      end
    end
  end

  def convert_df_row_fields(df_row, convert_fields, convert_callback) do
    Enum.reduce(convert_fields, df_row, fn convert_field, df_row ->
      convert_field = Atom.to_string(convert_field)
      Map.replace(df_row, convert_field, convert_callback.(df_row[convert_field]))
    end)
  end

  def convert_struct_fields(map, convert_fields, convert_callback) do
    Enum.reduce(convert_fields, map, fn convert_field, map ->
      Map.replace(map, convert_field, convert_callback.(map[convert_field]))
    end)
  end

  def to_df_type(type) do
    if type == Ecto.Enum do
      raise "Ecto.Enum is not supported"
    end

    @to_df_conversion_mapping[type]
  rescue
    exception ->
      reraise(exception, "Check if #{inspect(type)} is a valid Explorer.DataFrame dtype")
  end
end
