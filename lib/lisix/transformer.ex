defmodule Lisix.Transformer do
  @moduledoc """
  Transformer for Lisix - converts S-expressions into Elixir AST.
  """

  @doc """
  Transform an S-expression into Elixir AST.
  """
  def transform(sexpr) do
    transform_expr(sexpr, %{})
  end

  defp transform_expr(expr, env) do
    case expr do
      # Literals
      nil -> nil
      true -> true
      false -> false
      num when is_number(num) -> num
      str when is_binary(str) -> str
      
      # Keywords (Clojure-style)
      {:keyword, kw} -> kw
      
      # Vectors become lists
      {:vector, elements} ->
        Enum.map(elements, &transform_expr(&1, env))
      
      # Tuples become tuples
      {:tuple, elements} ->
        transformed_elements = Enum.map(elements, &transform_expr(&1, env))
        {:{}, [], transformed_elements}
      
      # Interpolation
      {:interpolate, var} ->
        quote do: unquote(Macro.var(var, nil))
      
      # Quote forms
      {:quote, expr} ->
        quote_expr(expr)
      
      {:quasiquote, expr} ->
        quasiquote_expr(expr, env)
      
      {:unquote, expr} ->
        transform_expr(expr, env)
      
      {:unquote_splicing, expr} ->
        # For unquote_splicing, we need to handle it differently
        # For now, just transform the inner expression
        transform_expr(expr, env)
      
      # Variables and macro/function references
      atom when is_atom(atom) ->
        if Map.has_key?(env, atom) do
          # Known variables become var nodes
          Macro.var(atom, nil)
        else
          # Everything else becomes potential macro/function call - let Elixir decide
          {atom, [], nil}
        end
      
      # S-expressions (function calls and special forms)
      [operator | args] when is_list(args) ->
        transform_call(operator, args, env)
      
      # Empty list
      [] -> []
      
      _ ->
        raise "Cannot transform expression: #{inspect(expr)}"
    end
  end

  # Transform function calls and special forms
  defp transform_call(operator, args, env) do
    case operator do
      # Special forms
      :defn -> transform_defn(args, env)
      :defp -> transform_defp(args, env)
      :def -> transform_def(args, env)
      :let -> transform_let(args, env)
      :if -> transform_if(args, env)
      :cond -> transform_cond(args, env)
      :case -> transform_case(args, env)
      :lambda -> transform_lambda(args, env)
      :fn -> transform_lambda(args, env)
      :do -> transform_do(args, env)
      :quote -> transform_quote(args, env)
      :quasiquote -> transform_quasiquote(args, env)
      :unquote -> transform_unquote(args, env)
      :try -> transform_try(args, env)
      
      # Arithmetic operators
      :+ -> transform_arithmetic(:+, args, env)
      :- -> transform_arithmetic(:-, args, env)
      :* -> transform_arithmetic(:*, args, env)
      :/ -> transform_arithmetic(:/, args, env)
      :rem -> transform_binary_op(:rem, args, env)
      :mod -> transform_binary_op(:rem, args, env)
      
      # Comparison operators
      :< -> transform_comparison(:<, args, env)
      :> -> transform_comparison(:>, args, env)
      :<= -> transform_comparison(:<=, args, env)
      :>= -> transform_comparison(:>=, args, env)
      :== -> transform_comparison(:==, args, env)
      :!= -> transform_comparison(:!=, args, env)
      := -> transform_comparison(:==, args, env)
      
      # Boolean operators
      :and -> transform_and(args, env)
      :or -> transform_or(args, env)
      :not -> transform_not(args, env)
      
      # List operations
      :car -> transform_car(args, env)
      :cdr -> transform_cdr(args, env)
      :cons -> transform_cons(args, env)
      :list -> transform_list(args, env)
      :first -> transform_car(args, env)
      :rest -> transform_cdr(args, env)
      :head -> transform_car(args, env)
      :tail -> transform_cdr(args, env)
      
      # Type predicates
      :nil? -> transform_nil_check(args, env)
      :empty? -> transform_empty_check(args, env)
      :list? -> transform_list_check(args, env)
      :atom? -> transform_atom_check(args, env)
      :number? -> transform_number_check(args, env)
      :string? -> transform_string_check(args, env)
      
      # String operations
      :str -> transform_str(args, env)
      
      # IO operations
      :print -> transform_print(args, env)
      :println -> transform_println(args, env)
      
      # Property access
      atom when is_atom(atom) ->
        # Check if it starts with : for keyword access
        atom_str = Atom.to_string(atom)
        if String.starts_with?(atom_str, ":") do
          key = String.slice(atom_str, 1..-1//1) |> String.to_atom()
          [map_expr | _] = args
          quote do
            Map.get(unquote(transform_expr(map_expr, env)), unquote(key))
          end
        else
          # Regular function call
          transform_function_call(atom, args, env)
        end
      
      # Dynamic function calls
      expr ->
        func = transform_expr(expr, env)
        transformed_args = Enum.map(args, &transform_expr(&1, env))
        quote do
          apply(unquote(func), unquote(transformed_args))
        end
    end
  end

  # Transform function definition
  defp transform_defn([name, args, body], env) when is_atom(name) do
    # Handle vector syntax for args
    arg_list = case args do
      {:vector, a} -> a
      a when is_list(a) -> a
      _ -> raise "Invalid arguments in defn: #{inspect(args)}"
    end
    
    arg_names = Enum.map(arg_list, fn
      atom when is_atom(atom) -> {atom, [], nil}
      {:keyword, kw} -> kw  # Transform keywords to atoms for pattern matching
      _ -> raise "Invalid argument in defn"
    end)
    
    new_env = Enum.reduce(arg_list, env, fn arg, acc ->
      case arg do
        atom when is_atom(atom) -> Map.put(acc, arg, true)
        {:keyword, kw} -> Map.put(acc, kw, true)
        _ -> acc
      end
    end)
    
    transformed_body = transform_expr(body, new_env)
    
    quote do
      def unquote(name)(unquote_splicing(arg_names)) do
        unquote(transformed_body)
      end
    end
  end

  # Multiple arity functions
  defp transform_defn([name | clauses], env) when is_atom(name) do
    transformed_clauses = Enum.map(clauses, fn
      [args, body] when is_list(args) ->
        arg_names = Enum.map(args, fn
          atom when is_atom(atom) -> {atom, [], nil}
          _ -> raise "Invalid argument"
        end)
        
        new_env = Enum.reduce(args, env, fn arg, acc ->
          Map.put(acc, arg, true)
        end)
        
        transformed_body = transform_expr(body, new_env)
        
        quote do
          def unquote(name)(unquote_splicing(arg_names)) do
            unquote(transformed_body)
          end
        end
    end)
    
    quote do
      unquote_splicing(transformed_clauses)
    end
  end

  # Private function
  defp transform_defp([name, args, body], env) do
    arg_names = Enum.map(args, fn
      atom when is_atom(atom) -> {atom, [], nil}
      _ -> raise "Invalid argument in defp"
    end)
    
    new_env = Enum.reduce(args, env, fn arg, acc ->
      Map.put(acc, arg, true)
    end)
    
    transformed_body = transform_expr(body, new_env)
    
    quote do
      defp unquote(name)(unquote_splicing(arg_names)) do
        unquote(transformed_body)
      end
    end
  end

  # Variable definition
  defp transform_def([name, value], env) when is_atom(name) do
    quote do
      unquote(Macro.var(name, nil)) = unquote(transform_expr(value, env))
    end
  end

  # Let bindings
  defp transform_let([bindings, body], env) when is_list(bindings) or is_tuple(bindings) do
    bindings_list = case bindings do
      {:vector, b} -> b
      b when is_list(b) -> b
    end
    
    {new_env, binding_asts} = transform_bindings(bindings_list, env, [])
    transformed_body = transform_expr(body, new_env)
    
    # Create nested variable bindings
    Enum.reduce(Enum.reverse(binding_asts), transformed_body, fn {var, val}, acc ->
      quote do
        unquote(var) = unquote(val)
        unquote(acc)
      end
    end)
  end

  defp transform_bindings([], env, acc), do: {env, Enum.reverse(acc)}
  defp transform_bindings([var, val | rest], env, acc) when is_atom(var) do
    transformed_val = transform_expr(val, env)
    new_env = Map.put(env, var, true)
    var_ast = Macro.var(var, nil)
    transform_bindings(rest, new_env, [{var_ast, transformed_val} | acc])
  end

  # If expression
  defp transform_if([condition, then_expr], env) do
    transform_if([condition, then_expr, nil], env)
  end
  
  defp transform_if([condition, then_expr, else_expr], env) do
    quote do
      if unquote(transform_expr(condition, env)) do
        unquote(transform_expr(then_expr, env))
      else
        unquote(transform_expr(else_expr, env))
      end
    end
  end

  # Cond expression
  defp transform_cond([clauses], env) when is_list(clauses) do
    transform_cond(clauses, env)
  end
  
  defp transform_cond(clauses, env) do
    transformed_clauses = Enum.map(clauses, fn
      {:vector, [test, expr]} -> transform_cond_clause(test, expr, env)
      [test, expr] -> transform_cond_clause(test, expr, env)
      _ -> raise "Invalid cond clause"
    end)
    
    quote do
      cond do
        unquote_splicing(transformed_clauses)
      end
    end
  end

  defp transform_cond_clause(test, expr, env) do
    {transform_expr(test, env), transform_expr(expr, env)}
  end

  # Case expression
  defp transform_case([expr | clauses], env) do
    transformed_expr = transform_expr(expr, env)
    transformed_clauses = Enum.map(clauses, fn
      [pattern, body] ->
        # For now, simple pattern matching
        {pattern, transform_expr(body, env)}
    end)
    
    quote do
      case unquote(transformed_expr) do
        unquote_splicing(transformed_clauses)
      end
    end
  end

  # Lambda/anonymous function
  defp transform_lambda([args, body], env) do
    # Handle vector syntax for args
    arg_list = case args do
      {:vector, a} -> a
      a when is_list(a) -> a
      _ -> raise "Invalid arguments in lambda: #{inspect(args)}"
    end
    arg_names = Enum.map(arg_list, fn
      atom when is_atom(atom) -> {atom, [], nil}
      _ -> raise "Invalid lambda argument"
    end)
    
    new_env = Enum.reduce(arg_list, env, fn arg, acc ->
      Map.put(acc, arg, true)
    end)
    
    transformed_body = transform_expr(body, new_env)
    
    quote do
      fn unquote_splicing(arg_names) -> unquote(transformed_body) end
    end
  end

  # Do block (multiple expressions)
  defp transform_do(exprs, env) do
    transformed = Enum.map(exprs, &transform_expr(&1, env))
    quote do
      unquote_splicing(transformed)
    end
  end

  # Quote
  defp transform_quote([expr], _env) do
    quote_expr(expr)
  end

  defp transform_quasiquote([expr], env) do
    quasiquote_expr(expr, env)
  end

  defp transform_unquote([expr], env) do
    transform_expr(expr, env)
  end

  # Arithmetic operations
  defp transform_arithmetic(op, args, env) when length(args) >= 2 do
    [first | rest] = Enum.map(args, &transform_expr(&1, env))
    
    Enum.reduce(rest, first, fn arg, acc ->
      quote do
        unquote(op)(unquote(acc), unquote(arg))
      end
    end)
  end
  
  defp transform_arithmetic(:-, [arg], env) do
    # Unary minus
    quote do
      -unquote(transform_expr(arg, env))
    end
  end

  defp transform_binary_op(op, [left, right], env) do
    quote do
      unquote(op)(
        unquote(transform_expr(left, env)),
        unquote(transform_expr(right, env))
      )
    end
  end

  # Comparison operations
  defp transform_comparison(op, [left, right], env) do
    quote do
      unquote(op)(
        unquote(transform_expr(left, env)),
        unquote(transform_expr(right, env))
      )
    end
  end

  # Boolean operations
  defp transform_and(args, env) do
    transformed = Enum.map(args, &transform_expr(&1, env))
    Enum.reduce(transformed, fn arg, acc ->
      quote do
        unquote(acc) and unquote(arg)
      end
    end)
  end

  defp transform_or(args, env) do
    transformed = Enum.map(args, &transform_expr(&1, env))
    Enum.reduce(transformed, fn arg, acc ->
      quote do
        unquote(acc) or unquote(arg)
      end
    end)
  end

  defp transform_not([arg], env) do
    quote do
      not unquote(transform_expr(arg, env))
    end
  end

  # List operations
  defp transform_car([list], env) do
    quote do
      hd(unquote(transform_expr(list, env)))
    end
  end

  defp transform_cdr([list], env) do
    quote do
      tl(unquote(transform_expr(list, env)))
    end
  end

  defp transform_cons([elem, list], env) do
    quote do
      [unquote(transform_expr(elem, env)) | unquote(transform_expr(list, env))]
    end
  end

  defp transform_list(args, env) do
    Enum.map(args, &transform_expr(&1, env))
  end

  # Type predicates
  defp transform_nil_check([arg], env) do
    quote do
      is_nil(unquote(transform_expr(arg, env)))
    end
  end

  defp transform_empty_check([arg], env) do
    quote do
      unquote(transform_expr(arg, env)) == []
    end
  end

  defp transform_list_check([arg], env) do
    quote do
      is_list(unquote(transform_expr(arg, env)))
    end
  end

  defp transform_atom_check([arg], env) do
    quote do
      is_atom(unquote(transform_expr(arg, env)))
    end
  end

  defp transform_number_check([arg], env) do
    quote do
      is_number(unquote(transform_expr(arg, env)))
    end
  end

  defp transform_string_check([arg], env) do
    quote do
      is_binary(unquote(transform_expr(arg, env)))
    end
  end

  # String operations
  defp transform_str(args, env) do
    transformed = Enum.map(args, &transform_expr(&1, env))
    quote do
      Enum.join([unquote_splicing(transformed)], "")
    end
  end

  # IO operations
  defp transform_print(args, env) do
    transformed = Enum.map(args, &transform_expr(&1, env))
    quote do
      IO.write(Enum.join([unquote_splicing(transformed)], " "))
    end
  end

  defp transform_println(args, env) do
    transformed = Enum.map(args, &transform_expr(&1, env))
    quote do
      IO.puts(Enum.join([unquote_splicing(transformed)], " "))
    end
  end

  # Try/catch
  defp transform_try([body | _rescue_clauses], env) do
    transformed_body = transform_expr(body, env)
    
    # Simple try/rescue for now
    quote do
      try do
        unquote(transformed_body)
      rescue
        e -> {:error, e}
      end
    end
  end

  # Regular function calls
  defp transform_function_call(func, args, env) do
    transformed_args = Enum.map(args, &transform_expr(&1, env))
    
    # Check if it's a module function call (has a dot)
    func_str = Atom.to_string(func)
    if String.contains?(func_str, ".") do
      [module_str, function_str] = String.split(func_str, ".", parts: 2)
      module = String.to_atom("Elixir." <> module_str)
      function = String.to_atom(function_str)
      
      quote do
        unquote(module).unquote(function)(unquote_splicing(transformed_args))
      end
    else
      # Local or imported function
      quote do
        unquote(func)(unquote_splicing(transformed_args))
      end
    end
  end

  # Quote an expression (prevent evaluation)
  defp quote_expr(expr) do
    case expr do
      atom when is_atom(atom) -> atom
      num when is_number(num) -> num
      str when is_binary(str) -> str
      nil -> nil
      true -> true
      false -> false
      list when is_list(list) ->
        Enum.map(list, &quote_expr/1)
      {:vector, elements} ->
        Enum.map(elements, &quote_expr/1)
      other -> other
    end
  end

  # Quasiquote (selective evaluation)
  defp quasiquote_expr(expr, env) do
    case expr do
      {:unquote, inner} ->
        transform_expr(inner, env)
      
      {:unquote_splicing, inner} ->
        # For quasiquote unquote_splicing, just transform the inner expression
        transform_expr(inner, env)
      
      list when is_list(list) ->
        Enum.map(list, &quasiquote_expr(&1, env))
      
      {:vector, elements} ->
        Enum.map(elements, &quasiquote_expr(&1, env))
      
      other ->
        quote_expr(other)
    end
  end
end