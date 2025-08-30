defmodule Lisix do
  @moduledoc """
  Lisix - A Lisp dialect that compiles to Elixir.
  
  ## Usage
  
      import Lisix.Sigil
      
      # Inline expressions
      result = ~L"(+ 1 2 3)"
      
      # Function definitions
      ~L\"\"\"
      (defn factorial [n]
        (if (<= n 1)
          1
          (* n (factorial (- n 1)))))
      \"\"\"
      
      # Using the function
      factorial(5)  # => 120
  """

  alias Lisix.{Tokenizer, Parser, Transformer}

  @doc """
  Evaluate a Lisp expression string.
  """
  def eval(string) when is_binary(string) do
    ast = string
          |> Tokenizer.tokenize()
          |> Parser.parse()
          |> Transformer.transform()
    
    {result, _} = Code.eval_quoted(ast)
    result
  end

  @doc """
  Parse a Lisp expression string into S-expression format.
  """
  def parse(string) when is_binary(string) do
    string
    |> Tokenizer.tokenize()
    |> Parser.parse()
  end

  @doc """
  Transform an S-expression into Elixir AST.
  """
  def to_ast(sexpr) do
    Transformer.transform(sexpr)
  end

  @doc """
  Compile a Lisp string to Elixir code string.
  """
  def compile(string) when is_binary(string) do
    ast = string
          |> Tokenizer.tokenize()
          |> Parser.parse()
          |> Transformer.transform()
    
    Macro.to_string(ast)
  end

  @doc """
  Pretty print an S-expression.
  """
  def pp(sexpr) do
    IO.puts(format_sexpr(sexpr))
    sexpr
  end

  defp format_sexpr(sexpr, indent \\ 0) do
    padding = String.duplicate("  ", indent)
    
    case sexpr do
      list when is_list(list) ->
        if simple_list?(list) do
          "(" <> Enum.map_join(list, " ", &format_sexpr(&1, 0)) <> ")"
        else
          "(\n" <>
          Enum.map_join(list, "\n", fn item ->
            padding <> "  " <> format_sexpr(item, indent + 1)
          end) <>
          "\n" <> padding <> ")"
        end
      
      atom when is_atom(atom) -> Atom.to_string(atom)
      num when is_number(num) -> to_string(num)
      str when is_binary(str) -> "\"" <> str <> "\""
      nil -> "nil"
      true -> "true"
      false -> "false"
      {:keyword, kw} -> ":" <> Atom.to_string(kw)
      {:vector, elements} ->
        "[" <> Enum.map_join(elements, " ", &format_sexpr(&1, 0)) <> "]"
      other -> inspect(other)
    end
  end

  defp simple_list?(list) do
    length(list) <= 3 and Enum.all?(list, fn
      l when is_list(l) -> false
      _ -> true
    end)
  end
end
