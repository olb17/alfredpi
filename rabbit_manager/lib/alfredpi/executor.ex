defmodule Alfredpi.Choregraphy.Executor do
  require Logger

  def execute(code) do
    with {:ok, tokens} <- parse_tokens(code, false),
         {:ok, tree} <- parse_grammar(tokens, false) do
      process_tree(tree)
    end
  end

  def validate(code, opts \\ []) do
    log = Keyword.get(opts, :log, false)

    with {:ok, tokens} <- parse_tokens(code, log),
         {:ok, _tree} <- parse_grammar(tokens, log) do
      :ok
    end
  end

  defp parse_tokens(text, log) do
    case :alfredpi_choregraphy_parser_lexer.string(String.to_charlist(text)) do
      {:ok, tokens, _line} ->
        if log, do: Logger.debug("Tokens: #{inspect(tokens, pretty: true)}")
        {:ok, tokens}

      {:error, {line_nb, :alfredpi_choregraphy_parser_lexer, {err, charlist}}, _} ->
        {:error, line_nb, err, to_string(charlist)}
    end
  end

  defp parse_grammar(tokens, log) do
    case :alfredpi_choregraphy.parse(tokens) do
      {:ok, tree} ->
        if log, do: Logger.debug("Parse result: #{inspect(tree, pretty: true)}")
        {:ok, tree}

      {:error, {line_nb, :alfredpi_choregraphy, [err, args]}} ->
        args = Enum.map(args, &to_string(&1))
        {:error, line_nb, to_string(err), args}
    end
  end

  defp process_tree(tree) do
    state = %{variables: builtin_variables(), actions: builtin_actions(), error: nil}
    process_tree(tree, state)
  end

  defp process_tree(tree, state) do
    Enum.reduce_while(tree, state, fn instr, state ->
      # Logger.debug("Processing: #{inspect(instr)}")
      process_instruction(instr, state)
    end)
  end

  defp builtin_actions() do
    %{
      "move_ear" => {Alfredpi.RabbitManager, :ear_move},
      "set_ear" => {Alfredpi.RabbitManager, :ear_position},
      "wait_ear" => {Alfredpi.RabbitManager, :ear_wait},
      "led_color" => {Alfredpi.RabbitManager, :leds_color},
      "play" => {Alfredpi.RabbitManager, :play_url},
      "sleep" => {Process, :sleep}
    }
  end

  defp builtin_variables() do
    %{
      "Left" => {:atom, :left},
      "Right" => {:atom, :right},
      "Both" => {:atom, :both},
      "Led0" => {:atom, :led_0},
      "Led1" => {:atom, :led_1},
      "Led2" => {:atom, :led_2},
      "Led3" => {:atom, :led_3},
      "Led4" => {:atom, :led_4}
    }
  end

  defp process_instruction({:assign, {:variable, _line_nb, name}, argument}, state) do
    variable = to_string(name)
    state = put_in(state, [:variables, variable], argument)
    #  Logger.debug("Updated state: #{inspect(state, pretty: true)}")
    {:cont, state}
  end

  defp process_instruction({:noop}, state) do
    {:cont, state}
  end

  defp process_instruction({:repeat, repetition, instrs}, state) do
    {:ok, rep} = process_argument(repetition, state)

    for _i <- 1..rep do
      process_tree(instrs, state)
    end

    {:cont, state}
  end

  defp process_instruction({:action, line_nb, name, arguments}, state) do
    process_action(name, line_nb, arguments, state)
  end

  defp process_instruction({:exec, parallel_instrs}, state) do
    tasks =
      Enum.map(parallel_instrs, fn instrs ->
        Task.async(fn ->
          #  Logger.debug("Parallel instructions: #{inspect(instrs, pretty: true)}")
          process_tree(instrs, state)
        end)
      end)

    Task.await_many(tasks, :infinity)
    {:cont, state}
  end

  defp process_action(name, line_nb, arguments, state) do
    name = to_string(name)

    with {:ok, ok_args} <- process_arguments(arguments, state),
         {:ok, {module, function}} <- find_action(state.actions, line_nb, name) do
      #  Logger.debug("Calling #{module}.#{function} with #{inspect(ok_args, pretty: true)}")
      try do
        # Call the action function with the processed arguments
        apply(module, function, ok_args)
        {:cont, state}
      rescue
        e in UndefinedFunctionError ->
          {:halt,
           %{state | error: "Error executing action #{name}/#{e.arity} at line #{line_nb}"}}
      end
    else
      {:error, error} ->
        {:halt, %{state | error: error}}
    end
  end

  defp find_action(actions, line_nb, name) do
    case Map.get(actions, name) do
      nil -> {:error, "unknown action name #{name}"}
      action -> {:ok, action}
    end
  end

  defp process_arguments(args, state) do
    {ok_args, error_args} =
      args
      |> Enum.map(&process_argument(&1, state))
      |> Enum.split_with(fn
        {:ok, _val} -> true
        _error -> false
      end)

    if length(error_args) > 0 do
      {:error, error_args |> Enum.map(&elem(&1, 1)) |> Enum.join(" / ")}
    else
      args = Enum.map(ok_args, &elem(&1, 1))
      {:ok, args}
    end
  end

  defp process_argument({:string, _line_nb, val}, _state), do: {:ok, val}
  defp process_argument({:int, _line_nb, val}, _state), do: {:ok, val}
  defp process_argument({:color, _line_nb, val}, _state), do: {:ok, to_string(val)}
  defp process_argument({:atom, val}, _state), do: {:ok, val}

  defp process_argument({:variable, line_nb, name}, state) do
    name = to_string(name)

    case Map.get(state.variables, name) do
      nil -> {:error, "unknown_variable #{name} at line #{line_nb}"}
      val -> process_argument(val, state)
    end
  end
end
