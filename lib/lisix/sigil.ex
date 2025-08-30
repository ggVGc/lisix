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
  - M - Module definition
  - q - Quote the expression
  """
  defmacro sigil_L(string, modifiers)

  # Default: evaluate expression
  defmacro sigil_L({:<<>>, _meta, [string]}, []) when is_binary(string) do
    ast = string
          |> Tokenizer.tokenize()
          |> Parser.parse()
          |> Transformer.transform()
    
    ast
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
        arg_names = Enum.map(args, fn
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

  # Module mode: define an entire module
  defmacro sigil_L({:<<>>, _meta, [string]}, [?M]) when is_binary(string) do
    ast = string
          |> Tokenizer.tokenize()
          |> Parser.parse()
    
    case ast do
      [:defmodule, module_name | body] ->
        transform_module(module_name, body)
      
      _ ->
        raise "Module mode requires a defmodule form"
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

  # Helper function to transform module definitions
  defp transform_module(module_name, body) do
    transformed_body = Enum.map(body, fn expr ->
      case expr do
        [:use, module] ->
          quote do: use unquote(module)
        
        [:import, module] ->
          quote do: import unquote(module)
        
        [:alias, module, opts] ->
          quote do: alias unquote(module), unquote(opts)
        
        [:defstruct, fields] ->
          quote do: defstruct unquote(fields)
        
        other ->
          Transformer.transform(other)
      end
    end)
    
    quote do
      defmodule unquote(module_name) do
        unquote_splicing(transformed_body)
      end
    end
  end
end