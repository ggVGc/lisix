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
          # Convert atom to proper module reference if needed
          module_ref = case module do
            atom when is_atom(atom) ->
              module_str = Atom.to_string(atom)
              cond do
                String.starts_with?(module_str, "Elixir.") ->
                  module
                String.contains?(module_str, ".") ->
                  # This is a dotted module name like "GenServer.Behaviour"
                  String.to_atom("Elixir." <> module_str)
                true ->
                  # Simple module name like "GenServer"
                  String.to_atom("Elixir." <> module_str)
              end
            other -> other
          end
          quote do: use unquote(module_ref)
        
        [:import, module] ->
          # Convert atom to proper module reference if needed
          module_ref = case module do
            atom when is_atom(atom) ->
              module_str = Atom.to_string(atom)
              cond do
                String.starts_with?(module_str, "Elixir.") ->
                  module
                String.contains?(module_str, ".") ->
                  # This is a dotted module name like "Lisix.Sigil"
                  String.to_atom("Elixir." <> module_str)
                true ->
                  # Simple module name like "GenServer"
                  String.to_atom("Elixir." <> module_str)
              end
            other -> other
          end
          quote do: import unquote(module_ref)
        
        [:alias, module, opts] ->
          quote do: (alias unquote(module), unquote(opts))
        
        [:defstruct, fields] ->
          quote do: defstruct unquote(fields)
        
        # Handle defn with pattern matching support
        [:defn, name, args, body] ->
          transform_module_defn(name, args, body)
        
        # Handle defn with multiple clauses (pattern matching)
        [:defn, name | clauses] ->
          transform_module_defn_clauses(name, clauses)
        
        # Handle defp (private functions)
        [:defp, name, args, body] ->
          transform_module_defp(name, args, body)
        
        # Handle GenServer callbacks and other special forms
        [:def, name, args, body] ->
          transform_module_defn(name, args, body)
          
        # Handle multiple clauses for callback functions
        [:def, name | clauses] ->
          transform_module_defn_clauses(name, clauses)
        
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

  # Transform function definition in module context
  defp transform_module_defn(name, args, body) do
    # Simple approach: let Transformer handle all argument patterns
    arg_patterns = case args do
      {:vector, arg_list} -> Enum.map(arg_list, &Transformer.transform/1)
      arg_list when is_list(arg_list) -> Enum.map(arg_list, &Transformer.transform/1)
      _ -> raise "Invalid arguments in function definition: #{inspect(args)}"
    end
    
    transformed_body = Transformer.transform(body)
    
    quote do
      def unquote(name)(unquote_splicing(arg_patterns)) do
        unquote(transformed_body)
      end
    end
  end

  # Transform private function definition
  defp transform_module_defp(name, args, body) do
    # Simple approach: let Transformer handle all argument patterns
    arg_patterns = case args do
      {:vector, arg_list} -> Enum.map(arg_list, &Transformer.transform/1)
      arg_list when is_list(arg_list) -> Enum.map(arg_list, &Transformer.transform/1)
      _ -> raise "Invalid arguments in function definition: #{inspect(args)}"
    end
    
    transformed_body = Transformer.transform(body)
    
    quote do
      defp unquote(name)(unquote_splicing(arg_patterns)) do
        unquote(transformed_body)
      end
    end
  end

  # Transform function with multiple clauses (for pattern matching)
  defp transform_module_defn_clauses(name, clauses) do
    clause_asts = Enum.map(clauses, fn
      {:vector, [args, body]} ->
        transform_single_clause(name, args, body, :def)
      [args, body] ->
        transform_single_clause(name, args, body, :def)
      {:vector, [args, guard, body]} ->
        transform_single_clause_with_guard(name, args, guard, body, :def)
      [args, guard, body] ->
        transform_single_clause_with_guard(name, args, guard, body, :def)
    end)
    
    quote do
      unquote_splicing(clause_asts)
    end
  end

  # Transform a single function clause
  defp transform_single_clause(name, args, body, def_type) do
    # Simple approach: let Transformer handle all argument patterns
    arg_patterns = case args do
      {:vector, arg_list} -> Enum.map(arg_list, &Transformer.transform/1)
      arg_list when is_list(arg_list) -> Enum.map(arg_list, &Transformer.transform/1)
      _ -> raise "Invalid arguments in function definition: #{inspect(args)}"
    end
    
    transformed_body = Transformer.transform(body)
    
    quote do
      unquote(def_type)(unquote(name)(unquote_splicing(arg_patterns))) do
        unquote(transformed_body)
      end
    end
  end

  # Transform a single function clause with explicit guard
  defp transform_single_clause_with_guard(name, args, guard, body, def_type) do
    # Simple approach: let Transformer handle all argument patterns
    arg_patterns = case args do
      {:vector, arg_list} -> Enum.map(arg_list, &Transformer.transform/1)
      arg_list when is_list(arg_list) -> Enum.map(arg_list, &Transformer.transform/1)
      _ -> raise "Invalid arguments in function definition: #{inspect(args)}"
    end
    
    guard_expr = Transformer.transform(guard)
    transformed_body = Transformer.transform(body)
    
    quote do
      unquote(def_type)(unquote(name)(unquote_splicing(arg_patterns))) when unquote(guard_expr) do
        unquote(transformed_body)
      end
    end
  end

end