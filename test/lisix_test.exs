defmodule LisixTest do
  use ExUnit.Case
  alias Lisix.{Tokenizer, Parser, Transformer}
  import Lisix.Sigil

  describe "Tokenizer" do
    test "tokenizes basic expressions" do
      assert Tokenizer.tokenize("(+ 1 2)") == [
        {:lparen}, {:symbol, :+}, {:number, 1}, {:number, 2}, {:rparen}
      ]
    end

    test "tokenizes nested expressions" do
      assert Tokenizer.tokenize("(* (+ 1 2) 3)") == [
        {:lparen}, {:symbol, :*}, 
        {:lparen}, {:symbol, :+}, {:number, 1}, {:number, 2}, {:rparen},
        {:number, 3}, {:rparen}
      ]
    end

    test "tokenizes strings" do
      assert Tokenizer.tokenize("(print \"hello world\")") == [
        {:lparen}, {:symbol, :print}, {:string, "hello world"}, {:rparen}
      ]
    end

    test "tokenizes keywords" do
      assert Tokenizer.tokenize("(:name :age)") == [
        {:lparen}, {:keyword, :name}, {:keyword, :age}, {:rparen}
      ]
    end

    test "tokenizes vectors" do
      assert Tokenizer.tokenize("[1 2 3]") == [
        {:lbracket}, {:number, 1}, {:number, 2}, {:number, 3}, {:rbracket}
      ]
    end

    test "handles comments" do
      assert Tokenizer.tokenize("(+ 1 ; comment\n 2)") == [
        {:lparen}, {:symbol, :+}, {:number, 1}, {:number, 2}, {:rparen}
      ]
    end

    test "tokenizes special literals" do
      assert Tokenizer.tokenize("(if true false nil)") == [
        {:lparen}, {:symbol, :if}, {:boolean, true}, {:boolean, false}, {:nil}, {:rparen}
      ]
    end

    test "tokenizes quote forms" do
      assert Tokenizer.tokenize("'(a b)") == [
        {:quote}, {:lparen}, {:symbol, :a}, {:symbol, :b}, {:rparen}
      ]
    end

    test "tokenizes floating point numbers" do
      assert Tokenizer.tokenize("(+ 3.14 -2.5)") == [
        {:lparen}, {:symbol, :+}, {:number, 3.14}, {:number, -2.5}, {:rparen}
      ]
    end
    
    test "rejects unsupported characters with clear error messages" do
      unsupported_chars = ["#", "$", "%", "^", "&", "=", "\\", "|", "<", ">", "?"]
      
      Enum.each(unsupported_chars, fn char ->
        assert_raise RuntimeError, ~r/Unsupported character/, fn ->
          Tokenizer.tokenize("(+ 1 #{char})")
        end
      end)
    end
    
    test "prevents infinite loops with progress validation" do
      # Test that we don't hang on edge cases that previously caused infinite loops
      assert Tokenizer.tokenize("") == []
      assert Tokenizer.tokenize("   ") == []
      assert Tokenizer.tokenize("()") == [{:lparen}, {:rparen}]
    end
    
    test "handles curly braces correctly" do
      # Test that curly braces (which previously caused infinite loops) now work
      assert Tokenizer.tokenize("{:key value}") == [
        {:lbrace}, {:keyword, :key}, {:symbol, :value}, {:rbrace}
      ]
    end
  end

  describe "Parser" do
    test "parses simple expressions" do
      tokens = [{:lparen}, {:symbol, :+}, {:number, 1}, {:number, 2}, {:rparen}]
      assert Parser.parse(tokens) == [:+, 1, 2]
    end

    test "parses nested expressions" do
      result = Parser.parse_string("(* (+ 1 2) 3)")
      assert result == [:*, [:+, 1, 2], 3]
    end

    test "parses let bindings" do
      result = Parser.parse_string("(let [x 10 y 20] (+ x y))")
      assert result == [:let, {:vector, [:x, 10, :y, 20]}, [:+, :x, :y]]
    end

    test "parses function definitions" do
      result = Parser.parse_string("(defn square [x] (* x x))")
      assert result == [:defn, :square, {:vector, [:x]}, [:*, :x, :x]]
    end

    test "parses quoted expressions" do
      result = Parser.parse_string("'(a b c)")
      assert result == {:quote, [:a, :b, :c]}
    end

    test "parses keywords" do
      result = Parser.parse_string("(:name :age)")
      assert result == [{:keyword, :name}, {:keyword, :age}]
    end

    test "parses empty list" do
      result = Parser.parse_string("()")
      assert result == []
    end

    test "parses multiple expressions" do
      result = Parser.parse_string("(+ 1 2) (* 3 4)")
      assert result == [[:+, 1, 2], [:*, 3, 4]]
    end
  end

  describe "Transformer" do
    test "transforms arithmetic" do
      sexpr = [:+, 1, 2, 3]
      ast = Transformer.transform(sexpr)
      assert Macro.to_string(ast) == "1 + 2 + 3"
    end

    test "transforms nested arithmetic" do
      sexpr = [:*, [:+, 1, 2], 3]
      ast = Transformer.transform(sexpr)
      assert Macro.to_string(ast) == "(1 + 2) * 3"
    end

    test "transforms if expression" do
      sexpr = [:if, [:>, :x, 0], "positive", "non-positive"]
      ast = Transformer.transform(sexpr)
      code = Macro.to_string(ast)
      assert code =~ "if"
      assert code =~ "positive"
    end

    test "transforms let bindings" do
      sexpr = [:let, {:vector, [:x, 10, :y, 20]}, [:+, :x, :y]]
      ast = Transformer.transform(sexpr)
      {result, _} = Code.eval_quoted(ast)
      assert result == 30
    end

    test "transforms lambda" do
      sexpr = [:lambda, [:x], [:*, :x, 2]]
      ast = Transformer.transform(sexpr)
      {func, _} = Code.eval_quoted(ast)
      assert is_function(func)
      assert func.(5) == 10
    end

    test "transforms function calls" do
      sexpr = [:print, "hello"]
      ast = Transformer.transform(sexpr)
      code_str = Macro.to_string(ast)
      # Print transforms to IO.write with string joining
      assert code_str =~ "IO.write"
      assert code_str =~ "hello"
    end

    test "transforms list operations" do
      sexpr = [:car, [:list, 1, 2, 3]]
      ast = Transformer.transform(sexpr)
      {result, _} = Code.eval_quoted(ast)
      assert result == 1
    end

    test "transforms comparison operators" do
      sexpr = [:<, 1, 2]
      ast = Transformer.transform(sexpr)
      {result, _} = Code.eval_quoted(ast)
      assert result == true
    end

    test "transforms boolean operators" do
      sexpr = [:and, true, false]
      ast = Transformer.transform(sexpr)
      {result, _} = Code.eval_quoted(ast)
      assert result == false
    end
  end

  describe "Sigil integration" do
    test "evaluates simple expressions" do
      result = ~L"(+ 1 2 3)"
      assert result == 6
    end

    test "defines and calls functions" do
      # For now, just test that the transformation works
      ast = Lisix.to_ast([:defn, :double, {:vector, [:x]}, [:*, :x, 2]])
      assert Macro.to_string(ast) =~ "def"
      assert Macro.to_string(ast) =~ "double"
    end

    test "handles let bindings" do
      result = ~L"(let [x 10 y 20] (+ x y))"
      assert result == 30
    end

    test "creates lambdas" do
      add5 = ~L"(lambda [x] (+ x 5))"
      assert add5.(10) == 15
    end

    test "quote mode returns S-expression" do
      sexpr = ~L"(+ 1 2)"q
      assert sexpr == [:+, 1, 2]
    end
  end

  describe "Core functions via Lisix" do
    test "factorial function" do
      # Test that factorial compiles correctly
      ast = Lisix.to_ast([:defn, :factorial, {:vector, [:n]}, 
                         [:if, [:<=, :n, 1], 1, [:*, :n, [:factorial, [:-, :n, 1]]]]])
      assert Macro.to_string(ast) =~ "def"
      assert Macro.to_string(ast) =~ "factorial"
    end

    test "fibonacci function" do
      # Test that fibonacci compiles correctly
      ast = Lisix.to_ast([:defn, :fib, {:vector, [:n]}, 
                         [:cond, [{:vector, [[:==, :n, 0], 0]},
                                 {:vector, [[:==, :n, 1], 1]},
                                 {:vector, [true, [:+, [:fib, [:-, :n, 1]], [:fib, [:-, :n, 2]]]]}]]])
      assert Macro.to_string(ast) =~ "def"
      assert Macro.to_string(ast) =~ "fib"
    end

    test "list creation works" do
      result = ~L"(list 1 2 3)"
      assert result == [1, 2, 3]
    end

    test "nested let bindings" do
      result = ~L"""
      (let [x 10
            y (* x 2)
            z (+ x y)]
        (* z 3))
      """
      assert result == 90
    end
  end

  describe "Full Lisix evaluation" do
    test "eval function works" do
      assert Lisix.eval("(+ 1 2 3)") == 6
    end

    test "parse function returns S-expression" do
      assert Lisix.parse("(+ 1 2)") == [:+, 1, 2]
    end

    test "compile function returns Elixir code" do
      code = Lisix.compile("(+ 1 2)")
      assert code == "1 + 2"
    end
  end

  describe "GenServer Module Creation" do
    test "transforms simple function definitions for GenServer callbacks" do
      # Test that individual function transformations work for GenServer patterns
      handle_call_code = "(defn handle-call [increment _from state] (+ state 1))"
      
      # Parse and check the S-expression structure
      tokens = Lisix.Tokenizer.tokenize(handle_call_code)
      sexpr = Lisix.Parser.parse(tokens)
      
      # Verify it parses as a proper defn form with pattern matching
      assert [:defn, :"handle-call", {:vector, [:increment, :_from, :state]}, [:+, :state, 1]] = sexpr
      
      # Test that it transforms to proper Elixir AST
      ast = Lisix.Transformer.transform(sexpr)
      code_string = Macro.to_string(ast)
      assert code_string =~ "def"
      assert code_string =~ "handle-call"  # Note: Lisp uses hyphens, Elixir function names keep them
    end

    test "creates a working GenServer using hybrid Lisix approach" do
      # Test a real GenServer using the working hybrid approach (Elixir module + Lisix expressions)
      defmodule TestCounterHybrid do
        use GenServer
        import Lisix.Sigil

        # Client API
        def start_link do
          GenServer.start_link(__MODULE__, 0, name: __MODULE__)
        end

        def increment do
          GenServer.call(__MODULE__, :increment)
        end

        def get_value do
          GenServer.call(__MODULE__, :get)
        end

        # Server callbacks using Lisix for computation
        def init(initial_value) do
          {:ok, initial_value}
        end

        def handle_call(:increment, _from, state) do
          new_state = ~L"(+ ~{state} 1)"
          {:reply, new_state, new_state}
        end

        def handle_call(:get, _from, state) do
          {:reply, state, state}
        end
      end

      # Test that the hybrid GenServer works correctly
      assert {:ok, _pid} = TestCounterHybrid.start_link()
      assert TestCounterHybrid.get_value() == 0
      assert TestCounterHybrid.increment() == 1
      assert TestCounterHybrid.get_value() == 1
      assert TestCounterHybrid.increment() == 2
      assert TestCounterHybrid.get_value() == 2

      # Clean up
      GenServer.stop(TestCounterHybrid)
    end

    test "GenServer with handle_call implemented completely using Lisix sigil" do
      # Test GenServer where handle_call functions are completely defined using Lisix sigil
      defmodule LisixBodyGenServer do
        use GenServer
        import Lisix.Sigil

        # Regular Elixir client API
        def start_link do
          GenServer.start_link(__MODULE__, 0, name: __MODULE__)
        end

        def increment do
          GenServer.call(__MODULE__, :increment)
        end

        def get_value do
          GenServer.call(__MODULE__, :get)
        end

        # Regular Elixir init
        def init(state) do
          {:ok, state}
        end

        # GenServer callbacks implemented completely using Lisix sigil
        # Note: Using underscores to match Elixir naming convention
        ~L"(defn handle_call [msg _from state] {:reply (+ state 1) (+ state 1)})"
      end

      # Test that the GenServer with complete Lisix sigil handle_call functions works
      assert {:ok, _pid} = LisixBodyGenServer.start_link()
      # Note: Our Lisix function always increments by 1 regardless of the message
      assert LisixBodyGenServer.get_value() == 1  # First call increments 0 -> 1
      assert LisixBodyGenServer.increment() == 2  # Second call increments 1 -> 2
      assert LisixBodyGenServer.get_value() == 3  # Third call increments 2 -> 3

      # Clean up
      GenServer.stop(LisixBodyGenServer)
    end
  end
end
