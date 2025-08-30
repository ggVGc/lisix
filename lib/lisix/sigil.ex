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
    # Handle vector syntax and pattern matching
    {arg_patterns, guards} = parse_args_and_guards(args)
    transformed_body = Transformer.transform(body)
    
    case guards do
      nil ->
        quote do
          def unquote(name)(unquote_splicing(arg_patterns)) do
            unquote(transformed_body)
          end
        end
      guard_expr ->
        quote do
          def unquote(name)(unquote_splicing(arg_patterns)) when unquote(guard_expr) do
            unquote(transformed_body)
          end
        end
    end
  end

  # Transform private function definition
  defp transform_module_defp(name, args, body) do
    {arg_patterns, guards} = parse_args_and_guards(args)
    transformed_body = Transformer.transform(body)
    
    case guards do
      nil ->
        quote do
          defp unquote(name)(unquote_splicing(arg_patterns)) do
            unquote(transformed_body)
          end
        end
      guard_expr ->
        quote do
          defp unquote(name)(unquote_splicing(arg_patterns)) when unquote(guard_expr) do
            unquote(transformed_body)
          end
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
    {arg_patterns, guards} = parse_args_and_guards(args)
    transformed_body = Transformer.transform(body)
    
    case guards do
      nil ->
        quote do
          unquote(def_type)(unquote(name)(unquote_splicing(arg_patterns))) do
            unquote(transformed_body)
          end
        end
      guard_expr ->
        quote do
          unquote(def_type)(unquote(name)(unquote_splicing(arg_patterns))) when unquote(guard_expr) do
            unquote(transformed_body)
          end
        end
    end
  end

  # Transform a single function clause with explicit guard
  defp transform_single_clause_with_guard(name, args, guard, body, def_type) do
    {arg_patterns, _} = parse_args_and_guards(args)
    guard_expr = Transformer.transform(guard)
    transformed_body = Transformer.transform(body)
    
    quote do
      unquote(def_type)(unquote(name)(unquote_splicing(arg_patterns))) when unquote(guard_expr) do
        unquote(transformed_body)
      end
    end
  end

  # Parse arguments and extract guards
  defp parse_args_and_guards(args) do
    case args do
      {:vector, arg_list} ->
        parse_args_list(arg_list)
      arg_list when is_list(arg_list) ->
        parse_args_list(arg_list)
      _ ->
        raise "Invalid arguments in function definition: #{inspect(args)}"
    end
  end

  # Parse individual arguments and extract patterns/guards
  defp parse_args_list(args) do
    {patterns, guards} = Enum.reduce(args, {[], []}, fn arg, {pat_acc, guard_acc} ->
      case arg do
        # Simple atom argument
        atom when is_atom(atom) ->
          {[{atom, [], nil} | pat_acc], guard_acc}
        
        # Pattern like [head | tail] becomes {:|, [], [head, tail]}
        [:"|", head, tail] ->
          pattern = {:|, [], [transform_pattern(head), transform_pattern(tail)]}
          {[pattern | pat_acc], guard_acc}
        
        # List pattern like [a, b, c]
        {:vector, elements} ->
          pattern = Enum.map(elements, &transform_pattern/1)
          {[pattern | pat_acc], guard_acc}
        
        # Tuple pattern like {:ok, value}
        list when is_list(list) ->
          case list do
            # Guard expression with :when
            [:when, pattern, guard] ->
              {[transform_pattern(pattern) | pat_acc], [Transformer.transform(guard) | guard_acc]}
            # Regular tuple/list pattern
            _ ->
              pattern = List.to_tuple(Enum.map(list, &transform_pattern/1))
              {[pattern | pat_acc], guard_acc}
          end
        
        # Literal values
        literal ->
          {[literal | pat_acc], guard_acc}
      end
    end)
    
    final_patterns = Enum.reverse(patterns)
    final_guards = case Enum.reverse(guards) do
      [] -> nil
      [single_guard] -> single_guard
      multiple_guards -> 
        # Combine multiple guards with 'and'
        Enum.reduce(multiple_guards, &{:and, [], [&2, &1]})
    end
    
    {final_patterns, final_guards}
  end

  # Transform pattern elements
  defp transform_pattern(pattern) do
    case pattern do
      atom when is_atom(atom) -> {atom, [], nil}
      {:vector, elements} -> Enum.map(elements, &transform_pattern/1)
      list when is_list(list) -> List.to_tuple(Enum.map(list, &transform_pattern/1))
      literal -> literal
    end
  end
end