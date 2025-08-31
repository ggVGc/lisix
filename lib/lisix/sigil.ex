defmodule Lisix.Sigil do
  @moduledoc """
  Sigil implementation for Lisix - provides ~L sigil for embedding Lisp code.
  
  Usage:
    ~L"(+ 1 2)"            # Inline expression
    ~L"(defn foo [x] x)"m  # Macro definition
    ~L"(defmodule ...)"M   # Module definition
  """

  alias Lisix.{Tokenizer, Parser, Transformer}

  @doc """
  The ~L sigil for Lisp expressions.
  
  Modifiers:
  - (none) - Evaluate as expression
  - m - Define as macro  
  - q - Quote the expression
  - i - Interactive mode
  """
  defmacro sigil_L(string, modifiers)

  # Default: evaluate expression
  defmacro sigil_L({:<<>>, _meta, [string]}, []) when is_binary(string) do
    parsed = string
             |> Tokenizer.tokenize()
             |> Parser.parse()
    
    case parsed do
      # Multiple expressions - the parser returns a list of expressions when there are multiple top-level forms
      exprs when is_list(exprs) and length(exprs) > 1 ->
        # Check if this is actually multiple top-level expressions vs a single S-expression
        first_elem = List.first(exprs)
        if is_list(first_elem) and is_atom(List.first(first_elem)) do
          # This looks like multiple S-expressions: [[:defn, ...], [:defn, ...]]
          transformed_exprs = Enum.map(exprs, &Transformer.transform/1)
          quote do
            unquote_splicing(transformed_exprs)
          end
        else
          # This is a single S-expression that happens to be a list
          Transformer.transform(parsed)
        end
      
      # Single expression - transform normally  
      single_expr ->
        Transformer.transform(single_expr)
    end
  end

  # Quote mode: return the S-expression as data
  defmacro sigil_L({:<<>>, _meta, [string]}, [?q]) when is_binary(string) do
    sexpr = string
            |> Tokenizer.tokenize()
            |> Parser.parse()
    
    Macro.escape(sexpr)
  end

  # Macro mode: define a macro
  defmacro sigil_L({:<<>>, _meta, [string]}, [?m]) when is_binary(string) do
    ast = string
          |> Tokenizer.tokenize()
          |> Parser.parse()
    
    case ast do
      [:defmacro, name, args, body] ->
        transformed_body = Transformer.transform(body)
        
        # Handle vector syntax for args
        arg_list = case args do
          {:vector, a} -> a
          a when is_list(a) -> a
          _ -> raise "Invalid arguments in defmacro: #{inspect(args)}"
        end
        
        arg_names = Enum.map(arg_list, fn
          atom when is_atom(atom) -> {atom, [], nil}
          _ -> raise "Invalid macro argument"
        end)
        
        quote do
          defmacro unquote(name)(unquote_splicing(arg_names)) do
            unquote(transformed_body)
          end
        end
      
      _ ->
        raise "Macro mode requires a defmacro form"
    end
  end


  # Interactive mode: evaluate and return result
  defmacro sigil_L({:<<>>, _meta, [string]}, [?i]) when is_binary(string) do
    ast = string
          |> Tokenizer.tokenize()
          |> Parser.parse()
          |> Transformer.transform()
    
    quote do
      unquote(ast)
    end
  end



end