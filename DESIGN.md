# Lisix: A Lisp-in-Elixir Language Design Document

## Executive Summary

Lisix is a compile-time Lisp dialect that seamlessly integrates with Elixir, providing authentic Lisp syntax while compiling to efficient BEAM bytecode. By leveraging Elixir's powerful macro system and sigils, Lisix allows developers to write pure Lisp code that benefits from Elixir's compile-time guarantees, OTP integration, and ecosystem.

## Core Philosophy

1. **Authentic Lisp Syntax**: Parentheses-based S-expressions, not approximations
2. **Zero Runtime Overhead**: All transformation happens at compile-time
3. **Full Elixir Interop**: Lisix modules can call Elixir and vice versa
4. **Compile-Time Safety**: Leverage Elixir's type checking and error detection
5. **Gradual Adoption**: Mix Lisix and Elixir in the same project

## Language Syntax

### Basic S-Expressions
```lisp
;; Arithmetic
(+ 1 2 3)                    ; => 6
(* (+ 2 3) 4)               ; => 20

;; Function calls
(print "Hello, World!")

;; Variables and binding
(let [(x 10)
      (y 20)]
  (+ x y))                   ; => 30
```

### Function Definitions
```lisp
;; Simple function
(defn square [x]
  (* x x))

;; Multiple arity
(defn greet
  ([name] (str "Hello, " name))
  ([name title] (str "Hello, " title " " name)))

;; Pattern matching
(defn factorial
  ([0] 1)
  ([n] (* n (factorial (- n 1)))))

;; Guards
(defn validate [x] :when (and (> x 0) (< x 100))
  {:valid x})
```

### Special Forms

#### Conditionals
```lisp
(if (> x 0)
  "positive"
  "non-positive")

(cond
  [(= x 0) "zero"]
  [(< x 0) "negative"]
  [true "positive"])

(case value
  [:ok result] (process result)
  [:error msg] (handle-error msg))
```

#### Let Bindings
```lisp
(let [(x 10)
      (y (* x 2))
      (z (+ x y))]
  (* z 3))
```

#### Lambda Expressions
```lisp
(lambda [x] (* x 2))

;; With closure
(defn make-adder [n]
  (lambda [x] (+ x n)))

(let [(add5 (make-adder 5))]
  (add5 10))                 ; => 15
```

### List Operations
```lisp
(car '(1 2 3))              ; => 1
(cdr '(1 2 3))              ; => (2 3)
(cons 0 '(1 2 3))           ; => (0 1 2 3)

(map (lambda [x] (* x 2)) '(1 2 3))      ; => (2 4 6)
(filter even? '(1 2 3 4 5))              ; => (2 4)
(reduce + 0 '(1 2 3 4 5))                ; => 15
```

### Macros
```lisp
(defmacro when [condition & body]
  `(if ~condition
     (do ~@body)
     nil))

(defmacro with-timeout [ms & body]
  `(Task.await
     (Task.async (fn [] ~@body))
     ~ms))
```

## Implementation Architecture

### 1. Tokenizer (`lib/lisix/tokenizer.ex`)

Converts raw Lisp text into a stream of tokens:

```elixir
defmodule Lisix.Tokenizer do
  def tokenize(string) do
    string
    |> String.graphemes()
    |> tokenize_impl([])
    |> Enum.reverse()
  end
  
  defp tokenize_impl([], acc), do: acc
  defp tokenize_impl(["(" | rest], acc), do: tokenize_impl(rest, [:lparen | acc])
  defp tokenize_impl([")" | rest], acc), do: tokenize_impl(rest, [:rparen | acc])
  defp tokenize_impl([" " | rest], acc), do: tokenize_impl(rest, acc)
  # ... handle numbers, symbols, strings, etc.
end
```

### 2. Parser (`lib/lisix/parser.ex`)

Transforms token stream into nested S-expression data structure:

```elixir
defmodule Lisix.Parser do
  def parse(tokens) do
    {sexpr, []} = parse_sexpr(tokens)
    sexpr
  end
  
  defp parse_sexpr([:lparen | rest]) do
    {elements, [:rparen | remaining]} = parse_list(rest, [])
    {elements, remaining}
  end
  
  defp parse_sexpr([{:symbol, sym} | rest]), do: {sym, rest}
  defp parse_sexpr([{:number, n} | rest]), do: {n, rest}
  defp parse_sexpr([{:string, s} | rest]), do: {s, rest}
  
  defp parse_list([:rparen | _] = tokens, acc), do: {Enum.reverse(acc), tokens}
  defp parse_list(tokens, acc) do
    {expr, rest} = parse_sexpr(tokens)
    parse_list(rest, [expr | acc])
  end
end
```

### 3. AST Transformer (`lib/lisix/transformer.ex`)

Converts S-expressions into Elixir AST:

```elixir
defmodule Lisix.Transformer do
  def transform(sexpr) do
    case sexpr do
      [:defn, name, args, body] ->
        quote do
          def unquote(name)(unquote_splicing(args)) do
            unquote(transform(body))
          end
        end
      
      [:let, bindings, body] ->
        transform_let(bindings, body)
      
      [:lambda, args, body] ->
        quote do
          fn unquote_splicing(args) -> unquote(transform(body)) end
        end
      
      [:if, cond, then_expr, else_expr] ->
        quote do
          if unquote(transform(cond)) do
            unquote(transform(then_expr))
          else
            unquote(transform(else_expr))
          end
        end
      
      [op | args] when op in [:+, :-, :*, :/] ->
        transform_arithmetic(op, args)
      
      [func | args] when is_atom(func) ->
        quote do
          unquote(func)(unquote_splicing(Enum.map(args, &transform/1)))
        end
      
      literal when is_atom(literal) or is_number(literal) or is_binary(literal) ->
        literal
    end
  end
end
```

### 4. Sigil Implementation (`lib/lisix/sigil.ex`)

Provides the ~L sigil for embedding Lisp code:

```elixir
defmodule Lisix.Sigil do
  defmacro sigil_L(string, modifiers) do
    ast = string
          |> Lisix.Tokenizer.tokenize()
          |> Lisix.Parser.parse()
          |> Lisix.Transformer.transform()
    
    case modifiers do
      [] -> ast                                    # Inline expression
      [?M] -> wrap_in_module(ast)                 # Module definition
      [?m] -> wrap_in_macro(ast)                  # Macro definition
      [?l] -> wrap_in_lazy(ast)                   # Lazy evaluation
    end
  end
  
  def sigil_L(string, [?i]) do
    # Interactive mode - for REPL
    Code.eval_quoted(transform(parse(tokenize(string))))
  end
end
```

### 5. Module-Level Support

For complete Lisp modules:

```lisp
~L"""
(defmodule Calculator
  (use GenServer)
  
  (defstruct [:value :history])
  
  (defn init [initial-value]
    {:ok (struct Calculator :value initial-value :history [])})
  
  (defn handle-call [:add n _from state]
    (let [(new-value (+ (:value state) n))
          (new-state (-> state
                        (assoc :value new-value)
                        (update :history conj [:add n])))]
      {:reply new-value new-state}))
  
  (defn add [pid n]
    (GenServer.call pid [:add n])))
"""M
```

## Compilation Pipeline

1. **Source File** (.lsx or ~L sigil in .ex)
2. **Tokenization** → Token stream
3. **Parsing** → S-expression tree
4. **Semantic Analysis** → Validate scoping, arity
5. **Transformation** → Elixir AST
6. **Macro Expansion** → Expanded Elixir code
7. **Compilation** → BEAM bytecode

## Integration Features

### Mix Compiler for .lsx Files

```elixir
# mix.exs
def project do
  [
    compilers: [:lisix] ++ Mix.compilers(),
    lisix_paths: ["lib_lisp"],
    ...
  ]
end
```

### Interoperability

```lisp
;; Calling Elixir from Lisix
(defn process-data [data]
  (-> data
      (Enum.map (lambda [x] (* x 2)))
      (Enum.filter (lambda [x] (> x 10)))
      (Enum.sum)))

;; Calling Lisix from Elixir
defmodule ElixirModule do
  def run do
    result = LisixModule.calculate(10, 20)
    IO.puts("Result: #{result}")
  end
end
```

### Error Handling

Compile-time errors with clear messages:

```
Compilation error in file lib/my_app.lsx:15
  Undefined variable 'y' in function 'calculate'
  
  13: (defn calculate [x]
  14:   (let [(z (* x 2))]
  15:     (+ z y)))  ; <- error here
         ^
```

## Advanced Features

### Tail Call Optimization
```lisp
(defn factorial
  ([n] (factorial n 1))
  ([0 acc] acc)
  ([n acc] (recur (- n 1) (* n acc))))
```

### Protocols and Implementations
```lisp
(defprotocol Drawable
  (draw [shape canvas]))

(defimpl Drawable Circle
  (defn draw [circle canvas]
    (Canvas.draw-circle canvas (:x circle) (:y circle) (:radius circle))))
```

### Async and Processes
```lisp
(defn parallel-map [f lst]
  (let [(tasks (map (lambda [x] (Task.async (lambda [] (f x)))) lst))]
    (map Task.await tasks)))
```

## Standard Library

### Core Functions
- List operations: `car`, `cdr`, `cons`, `list`, `append`
- Higher-order: `map`, `filter`, `reduce`, `fold`, `scan`
- Predicates: `nil?`, `empty?`, `even?`, `odd?`, `zero?`
- Math: `+`, `-`, `*`, `/`, `rem`, `mod`, `abs`, `sqrt`
- Comparison: `<`, `>`, `<=`, `>=`, `=`, `!=`
- Logic: `and`, `or`, `not`, `xor`

### Data Structures
- Lists: First-class support with literal syntax
- Maps: `{:key value}` syntax
- Sets: `#{1 2 3}` syntax
- Keywords: `:keyword` syntax
- Atoms: `'atom` syntax

## Performance Considerations

1. **Zero Runtime Overhead**: All Lisp→Elixir transformation at compile time
2. **Same Performance as Elixir**: Compiles to identical BEAM bytecode
3. **Tail Call Optimization**: Via `recur` special form
4. **Lazy Evaluation**: Optional with `~L...l` modifier
5. **Memoization**: Built-in support with `defmemo`

## Tooling

### Editor Support
- Syntax highlighting for .lsx files
- Indentation rules for S-expressions
- Bracket matching and rainbow parentheses
- Inline evaluation in REPL

### Development Tools
- REPL with Lisp syntax
- Debugger integration
- Code formatter (`mix format.lisix`)
- Documentation generation
- Property-based testing support

## Implementation Roadmap

### Phase 1: Core (Weeks 1-2)
- Tokenizer and Parser
- Basic transformer
- Simple ~L sigil
- Arithmetic and basic functions

### Phase 2: Special Forms (Weeks 3-4)
- if, cond, case
- let bindings
- lambda expressions
- defn with pattern matching

### Phase 3: Integration (Weeks 5-6)
- Module definitions
- Elixir interop
- Mix compiler task
- Error handling

### Phase 4: Advanced (Weeks 7-8)
- Macros
- Protocols
- GenServer support
- Tail recursion

### Phase 5: Polish (Weeks 9-10)
- Standard library
- Documentation
- Testing suite
- Performance optimization

## Testing Strategy

1. **Unit Tests**: Each component (tokenizer, parser, transformer)
2. **Integration Tests**: Complete programs
3. **Property Tests**: Parser correctness
4. **Compatibility Tests**: Elixir interop
5. **Performance Tests**: Benchmark vs pure Elixir

## Success Metrics

- ✅ Full Lisp syntax support
- ✅ 100% Elixir interoperability
- ✅ Compile-time error detection
- ✅ Performance within 5% of Elixir
- ✅ Support for OTP patterns
- ✅ Developer tooling (REPL, formatter)
- ✅ Documentation and examples
- ✅ Community adoption

## Example: Complete Web Server

```lisp
~L"""
(defmodule WebServer
  (use Plug.Router)
  (use Plug.Cowboy)
  
  (plug :match)
  (plug :dispatch)
  
  (get "/" []
    (send-resp conn 200 "Welcome to Lisix!"))
  
  (get "/factorial/:n" []
    (let [(num (String.to-integer (:n params)))
          (result (factorial num))]
      (send-resp conn 200 (str "Factorial of " num " is " result))))
  
  (defn factorial [n]
    (if (<= n 1)
      1
      (* n (factorial (- n 1)))))
  
  (defn start-link []
    (Plug.Cowboy.http WebServer [] [port: 4000])))
"""M
```

This design enables writing production Elixir applications entirely in Lisp syntax while maintaining all of Elixir's benefits and ecosystem compatibility.