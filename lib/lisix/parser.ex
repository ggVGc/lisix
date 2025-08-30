defmodule Lisix.Parser do
  @moduledoc """
  Parser for Lisix - converts tokens into S-expression AST.
  """

  alias Lisix.Tokenizer

  @type sexpr :: 
    atom() |
    number() |
    binary() |
    nil |
    boolean() |
    list(sexpr()) |
    {:quote, sexpr()} |
    {:quasiquote, sexpr()} |
    {:unquote, sexpr()} |
    {:unquote_splicing, sexpr()} |
    {:keyword, atom()} |
    {:vector, list(sexpr())} |
    {:interpolate, atom()}

  @doc """
  Parse a list of tokens into an S-expression.
  """
  @spec parse([Tokenizer.token()]) :: sexpr() | list(sexpr())
  def parse(tokens) when is_list(tokens) do
    case parse_all(tokens, []) do
      {[], [expr]} -> expr
      {[], exprs} -> exprs
      {remaining, _} -> 
        raise "Unexpected tokens remaining: #{inspect(remaining)}"
    end
  end

  @doc """
  Parse a string directly into an S-expression.
  """
  @spec parse_string(binary()) :: sexpr() | list(sexpr())
  def parse_string(input) when is_binary(input) do
    input
    |> Tokenizer.tokenize()
    |> parse()
  end

  # Parse multiple expressions
  defp parse_all([], acc), do: {[], Enum.reverse(acc)}
  defp parse_all(tokens, acc) do
    case parse_expr(tokens) do
      {remaining, expr} ->
        parse_all(remaining, [expr | acc])
    end
  rescue
    _ -> {[], Enum.reverse(acc)}
  end

  # Parse a single expression
  defp parse_expr([]), do: raise("Unexpected end of input")
  
  # Lists (S-expressions)
  defp parse_expr([{:lparen} | rest]) do
    parse_list(rest, [])
  end
  
  # Vectors
  defp parse_expr([{:lbracket} | rest]) do
    {remaining, elements} = parse_vector(rest, [])
    {remaining, {:vector, elements}}
  end
  
  # Tuples/Maps
  defp parse_expr([{:lbrace} | rest]) do
    {remaining, elements} = parse_tuple(rest, [])
    {remaining, {:tuple, elements}}
  end
  
  # Quote forms
  defp parse_expr([{:quote} | rest]) do
    {remaining, expr} = parse_expr(rest)
    {remaining, {:quote, expr}}
  end
  
  defp parse_expr([{:quasiquote} | rest]) do
    {remaining, expr} = parse_expr(rest)
    {remaining, {:quasiquote, expr}}
  end
  
  defp parse_expr([{:unquote} | rest]) do
    {remaining, expr} = parse_expr(rest)
    {remaining, {:unquote, expr}}
  end
  
  defp parse_expr([{:unquote_splicing} | rest]) do
    {remaining, expr} = parse_expr(rest)
    {remaining, {:unquote_splicing, expr}}
  end
  
  # Interpolation
  defp parse_expr([{:interpolate, var} | rest]) do
    {rest, {:interpolate, var}}
  end
  
  # Literals
  defp parse_expr([{:symbol, sym} | rest]) do
    {rest, sym}
  end
  
  defp parse_expr([{:number, num} | rest]) do
    {rest, num}
  end
  
  defp parse_expr([{:string, str} | rest]) do
    {rest, str}
  end
  
  defp parse_expr([{:keyword, kw} | rest]) do
    {rest, {:keyword, kw}}
  end
  
  defp parse_expr([{:boolean, bool} | rest]) do
    {rest, bool}
  end
  
  defp parse_expr([{:nil} | rest]) do
    {rest, nil}
  end
  
  defp parse_expr([token | _]) do
    raise "Unexpected token: #{inspect(token)}"
  end
  
  # Parse list elements until closing paren
  defp parse_list([{:rparen} | rest], acc) do
    {rest, Enum.reverse(acc)}
  end
  
  defp parse_list([], _acc) do
    raise "Unclosed list - missing )"
  end
  
  defp parse_list(tokens, acc) do
    {remaining, expr} = parse_expr(tokens)
    parse_list(remaining, [expr | acc])
  end
  
  # Parse vector elements until closing bracket
  defp parse_vector([{:rbracket} | rest], acc) do
    {rest, Enum.reverse(acc)}
  end
  
  defp parse_vector([], _acc) do
    raise "Unclosed vector - missing ]"
  end
  
  defp parse_vector(tokens, acc) do
    {remaining, expr} = parse_expr(tokens)
    parse_vector(remaining, [expr | acc])
  end
  
  # Parse tuple elements until closing brace
  defp parse_tuple([{:rbrace} | rest], acc) do
    {rest, Enum.reverse(acc)}
  end
  
  defp parse_tuple([], _acc) do
    raise "Unclosed tuple - missing }"
  end
  
  defp parse_tuple(tokens, acc) do
    {remaining, expr} = parse_expr(tokens)
    parse_tuple(remaining, [expr | acc])
  end
end