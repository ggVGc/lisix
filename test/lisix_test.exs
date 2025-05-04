defmodule LispixTest do
  use ExUnit.Case
  import Lisix

  # Lisix.ldef double_argument(arg) do
  #   # arg * 2
  #   (:* arg 2)
  # end

  # Lisix.ldef :yeo

  Lisix.ldef yeo

  test "calls defined function" do
    a = yeo()
    |> IO.inspect(label: "result")
    expr = quote do Lisix.ldef yeo end

    # yeo |> IO.inspect(label: "f")
    # ex =
    #   quote do
    #     ~w(
    #       {def {double_argument arg}
    #         {* arg 2}}
    #     )
    #   end

    # ex
    # |> IO.inspect(label: "ex")

    expr
    |> Macro.expand_once(__ENV__)
    |> IO.inspect(label: "expanded")

    # assert double_argument(100) == 200
  end
end
