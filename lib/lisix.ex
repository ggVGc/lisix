defmodule Lispix do
  defmacro ldef(call, _expr \\ nil) do
    quote do
      def(unquote(call), nil)
    end
  end
end
