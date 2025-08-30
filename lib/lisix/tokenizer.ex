defmodule Lisix.Tokenizer do
  @moduledoc """
  Tokenizer for Lisix - converts Lisp source code into tokens.
  """

  @type token :: 
    {:lparen} |
    {:rparen} |
    {:lbracket} |
    {:rbracket} |
    {:quote} |
    {:quasiquote} |
    {:unquote} |
    {:unquote_splicing} |
    {:symbol, atom()} |
    {:number, number()} |
    {:string, binary()} |
    {:keyword, atom()} |
    {:boolean, boolean()} |
    {:nil}

  @doc """
  Tokenize a string of Lisp code into a list of tokens.
  """
  @spec tokenize(binary()) :: [token()]
  def tokenize(input) when is_binary(input) do
    input
    |> String.to_charlist()
    |> tokenize_impl([])
    |> Enum.reverse()
  end

  defp tokenize_impl([], acc), do: acc
  
  # Skip whitespace
  defp tokenize_impl([char | rest], acc) when char in ~c" \t\n\r" do
    tokenize_impl(rest, acc)
  end
  
  # Comments - skip until end of line
  defp tokenize_impl([?; | rest], acc) do
    rest
    |> skip_until_newline()
    |> tokenize_impl(acc)
  end
  
  # Parentheses
  defp tokenize_impl([?( | rest], acc) do
    tokenize_impl(rest, [{:lparen} | acc])
  end
  
  defp tokenize_impl([?) | rest], acc) do
    tokenize_impl(rest, [{:rparen} | acc])
  end
  
  # Brackets for vectors/arrays
  defp tokenize_impl([?[ | rest], acc) do
    tokenize_impl(rest, [{:lbracket} | acc])
  end
  
  defp tokenize_impl([?] | rest], acc) do
    tokenize_impl(rest, [{:rbracket} | acc])
  end
  
  # Quote forms
  defp tokenize_impl([?' | rest], acc) do
    tokenize_impl(rest, [{:quote} | acc])
  end
  
  defp tokenize_impl([?` | rest], acc) do
    tokenize_impl(rest, [{:quasiquote} | acc])
  end
  
  defp tokenize_impl([?~, ?@ | rest], acc) do
    tokenize_impl(rest, [{:unquote_splicing} | acc])
  end
  
  defp tokenize_impl([?~, ?{ | rest], acc) do
    # Interpolation syntax ~{expr}
    {expr, [?} | remaining]} = collect_until(rest, ?}, [])
    var_name = expr |> to_string() |> String.to_atom()
    tokenize_impl(remaining, [{:interpolate, var_name} | acc])
  end
  
  defp tokenize_impl([?~ | rest], acc) do
    tokenize_impl(rest, [{:unquote} | acc])
  end
  
  # Strings
  defp tokenize_impl([?" | rest], acc) do
    {string_chars, rest_after_string} = collect_string(rest, [])
    string = string_chars |> Enum.reverse() |> to_string()
    tokenize_impl(rest_after_string, [{:string, string} | acc])
  end
  
  # Numbers (including negative)
  defp tokenize_impl([?- | rest] = input, acc) do
    case rest do
      [digit | _] when digit in ?0..?9 ->
        tokenize_number(input, acc)
      _ ->
        # Just a minus symbol
        tokenize_impl(rest, [{:symbol, :-} | acc])
    end
  end
  
  defp tokenize_impl([digit | _] = input, acc) when digit in ?0..?9 do
    tokenize_number(input, acc)
  end
  
  # Keywords (Clojure style)
  defp tokenize_impl([?: | rest], acc) do
    {keyword_chars, remaining} = collect_symbol(rest, [])
    keyword = keyword_chars |> Enum.reverse() |> to_string() |> String.to_atom()
    tokenize_impl(remaining, [{:keyword, keyword} | acc])
  end
  
  # Symbols and special literals
  defp tokenize_impl(input, acc) do
    {symbol_chars, rest} = collect_symbol(input, [])
    
    case symbol_chars |> Enum.reverse() |> to_string() do
      "true" -> tokenize_impl(rest, [{:boolean, true} | acc])
      "false" -> tokenize_impl(rest, [{:boolean, false} | acc])
      "nil" -> tokenize_impl(rest, [{:nil} | acc])
      symbol_str -> 
        symbol = String.to_atom(symbol_str)
        tokenize_impl(rest, [{:symbol, symbol} | acc])
    end
  end
  
  # Helper functions
  
  defp skip_until_newline([?\n | rest]), do: rest
  defp skip_until_newline([_ | rest]), do: skip_until_newline(rest)
  defp skip_until_newline([]), do: []
  
  defp collect_string([?" | rest], acc), do: {acc, rest}
  defp collect_string([?\\, ?" | rest], acc) do
    collect_string(rest, [?" | acc])
  end
  defp collect_string([?\\, ?n | rest], acc) do
    collect_string(rest, [?\n | acc])
  end
  defp collect_string([?\\, ?t | rest], acc) do
    collect_string(rest, [?\t | acc])
  end
  defp collect_string([?\\, ?r | rest], acc) do
    collect_string(rest, [?\r | acc])
  end
  defp collect_string([?\\, ?\\ | rest], acc) do
    collect_string(rest, [?\\ | acc])
  end
  defp collect_string([char | rest], acc) do
    collect_string(rest, [char | acc])
  end
  defp collect_string([], _acc) do
    raise "Unterminated string"
  end
  
  defp collect_symbol([], acc), do: {acc, []}
  defp collect_symbol([char | _] = input, acc) when char in ~c" \t\n\r()[]\";}~" do
    {acc, input}
  end
  defp collect_symbol([char | rest], acc) do
    collect_symbol(rest, [char | acc])
  end
  
  defp collect_until([], _char, acc), do: {Enum.reverse(acc), []}
  defp collect_until([char | rest], char, acc), do: {Enum.reverse(acc), [char | rest]}
  defp collect_until([c | rest], char, acc), do: collect_until(rest, char, [c | acc])
  
  defp tokenize_number(input, acc) do
    {number_str, rest} = collect_number(input, [])
    
    number = case number_str |> Enum.reverse() |> to_string() do
      str ->
        cond do
          String.contains?(str, ".") ->
            String.to_float(str)
          true ->
            String.to_integer(str)
        end
    end
    
    tokenize_impl(rest, [{:number, number} | acc])
  end
  
  defp collect_number([], acc), do: {acc, []}
  defp collect_number([char | rest], acc) when char in ?0..?9 do
    collect_number(rest, [char | acc])
  end
  defp collect_number([?. | rest], acc) do
    if Enum.any?(acc, &(&1 == ?.)) do
      # Already has a decimal point
      {acc, [?. | rest]}
    else
      collect_number(rest, [?. | acc])
    end
  end
  defp collect_number([?- | rest], []) do
    # Leading minus sign
    collect_number(rest, [?-])
  end
  defp collect_number(input, acc), do: {acc, input}
end