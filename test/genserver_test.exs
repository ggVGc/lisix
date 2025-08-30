defmodule GenServerTest do
  use ExUnit.Case

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
      # Test GenServer where all function bodies are defined in one large Lisix sigil block
      defmodule LisixBodyGenServer do
        use GenServer
        import Lisix.Sigil

        # All functions implemented in one large Lisix sigil block
        ~L"""
        (defn start_link []
          (GenServer.start_link __MODULE__ 0 [{:name __MODULE__}]))

        (defn increment []
          (GenServer.call __MODULE__ :increment))

        (defn get_value []
          (GenServer.call __MODULE__ :get))

        (defn init [state]
          {:ok state})

        (defn handle_call [:increment _from state]
          (let [new-state (+ state 1)]
            {:reply new-state new-state}))

        (defn handle_call [:get _from state]
          {:reply state state})
        """
      end

      # Test that the GenServer with complete Lisix sigil handle_call functions works
      assert {:ok, _pid} = LisixBodyGenServer.start_link()
      assert LisixBodyGenServer.get_value() == 0
      assert LisixBodyGenServer.increment() == 1
      assert LisixBodyGenServer.get_value() == 1

      # Clean up
      GenServer.stop(LisixBodyGenServer)
    end
  end
end
