defmodule Lisix do
  defmacro ldef(name) do
    fun_name =
      case name do
        {sym, [], _mod} -> sym
        x -> x
      end

    quote do
      def unquote(fun_name) do
        123
      end
    end
  end
end
