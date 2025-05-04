defmodule LispixTest do
  use ExUnit.Case
  require Lispix

  # Lispix.ldef double_argument(arg) do
  #   # arg * 2
  #   (:* arg 2)
  # end

  test "calls defined function" do
    ex =
      quote do
          ~w({def {double_argument arg}
            {* arg 2}}
        )
      end

    Macro.expand_once(ex, __ENV__)
    |> IO.inspect(label: "expanded")

    # assert double_argument(100) == 200
  end
end
