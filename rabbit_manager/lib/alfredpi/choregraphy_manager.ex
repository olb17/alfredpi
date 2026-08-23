defmodule Alfredpi.ChoregraphyManager do
  use GenServer
  require Logger

  alias Alfredpi.RabbitManager
  alias Alfredpi.Choregraphy.Executor
  alias Alfredpi.ChoregraphyAgent
  alias Alfredpi.ChoregraphyManager.Choregraphy

  defmodule Choregraphy do
    alias Alfredpi.ChoregraphyManager
    alias Alfredpi.ChoregraphyAgent
    use Ecto.Schema
    import Ecto.Changeset

    @system_code "SYSTEM_"

    embedded_schema do
      field(:name, :string)
      field(:code, :string)
      field(:actions, :string)
    end

    def changeset(params, choregraphy \\ %Choregraphy{}) do
      choregraphy
      |> cast(params, [:name, :code, :actions])
      |> validate_required([:name, :code, :actions])
      |> validate_choregraphy_grammar(:actions)
      |> validate_choregraphy_code(:code)
    end

    def changeset_execute(params, choregraphy \\ %Choregraphy{}) do
      choregraphy
      |> cast(params, [:actions])
      |> validate_required([:actions])
      |> validate_choregraphy_grammar(:actions)
    end

    defp validate_choregraphy_code(changeset, field) when is_atom(field) do
      validate_change(changeset, field, fn field, value ->
        cond do
          String.starts_with?(value, @system_code) ->
            [{field, "Cannot start with #{@system_code} (reserved for system choregraphy"}]

          not Regex.match?(~r/[A-Z0-9]+/, value) ->
            [{field, "code can only be composed of A-Z 0-9 and _ characters."}]

          true ->
            []
        end
      end)
    end

    defp validate_choregraphy_grammar(changeset, field) when is_atom(field) do
      validate_change(changeset, field, fn field, value ->
        case ChoregraphyManager.validate_choregraphy(value) do
          :ok -> []
          error -> [{field, "#{inspect(error)}"}]
        end
      end)
    end

    def is_system(%__MODULE__{code: code}) do
      String.starts_with?(code, @system_code)
    end
  end

  defstruct choregraphy_dir: nil,
            running_task_ref: nil

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def list_choregraphy() do
    ChoregraphyAgent.list_choregraphy()
  end

  def get_choregraphy_by_code(code) do
    ChoregraphyAgent.get_choregraphy_by_code(code)
  end

  def update_choregraphy(%Choregraphy{} = chor) do
    GenServer.call(__MODULE__, {:update_choregraphy, chor})
  end

  def delete_choregraphy(%Choregraphy{} = chor) do
    GenServer.call(__MODULE__, {:delete_choregraphy, chor})
  end

  def validate_choregraphy(actions, opts \\ []) do
    log = Keyword.get(opts, :log, false)
    Executor.validate(actions, log: log)
  end

  def execute_choregraphy(code) do
    GenServer.call(__MODULE__, {:execute_choregraphy, code})
  end

  def execute_choregraphy_actions(actions) do
    GenServer.call(__MODULE__, {:execute_actions, actions})
  end

  def is_choregraphy_running() do
    GenServer.call(__MODULE__, :is_choregraphy_running)
  end

  @impl true
  def init(chor_dir) do
    File.mkdir_p(chor_dir)

    state = %__MODULE__{choregraphy_dir: chor_dir}

    build_initial_state(state)
    |> ChoregraphyAgent.load_state()

    {:ok, state}
  end

  @impl true
  def handle_call({:update_choregraphy, chor}, _from, state) do
    if Choregraphy.is_system(chor) do
      {:reply, {:error, :cannot_save_system_choregraphy, chor}, state}
    else
      :ok = save_choregraphy_file(state.choregraphy_dir, chor)
      :ok = ChoregraphyAgent.update_choregraphy(chor)
      {:reply, {:ok, chor}, state}
    end
  end

  def handle_call({:delete_choregraphy, chor}, _from, state) do
    if Choregraphy.is_system(chor) do
      {:reply, {:error, :cannot_delete_system_choregraphy, chor}, state}
    else
      :ok = delete_choregraphy_file(state.choregraphy_dir, chor)
      :ok = ChoregraphyAgent.delete_choregraphy(chor)
      {:reply, :ok, state}
    end
  end

  def handle_call(:is_choregraphy_running, _from, %{running_task_ref: running_task_ref} = state) do
    {:reply, is_reference(running_task_ref), state}
  end

  def handle_call(
        {:execute_choregraphy, _code},
        _from,
        %{running_task_ref: running_task_ref} = state
      )
      when is_reference(running_task_ref) do
    {:reply, {:error, :already_running_choregraphy}, state}
  end

  def handle_call({:execute_choregraphy, code}, _from, state) do
    case ChoregraphyAgent.get_choregraphy_by_code(code) do
      nil -> {:reply, {:error, :unknown_choregraphy, code}, state}
      choregraphy -> handle_call({:execute_actions, choregraphy.actions}, {nil, nil}, state)
    end
  end

  def handle_call(
        {:execute_actions, _actions},
        _from,
        %{running_task_ref: running_task_ref} = state
      )
      when is_reference(running_task_ref) do
    {:reply, {:error, :already_running_choregraphy}, state}
  end

  def handle_call({:execute_actions, actions}, {from, _}, state) do
    task =
      Task.async(fn ->
        res = Executor.execute(actions)

        case res do
          %{error: nil} ->
            :ok

          %{error: error} ->
            Logger.error("Choregraphy execution failed: #{inspect(error)}")

            if from != nil do
              send(from, {:choregraphy_error, error})
            end
        end
      end)

    RabbitManager.publish_event({:choregraphy, {:running, nil}})

    {:reply, :ok, %{state | running_task_ref: task.ref}}
  end

  @impl true
  def handle_info({ref, _result}, %{running_task_ref: ref} = state) do
    # The task succeed so we can demonitor its reference
    Process.demonitor(ref, [:flush])
    RabbitManager.publish_event({:choregraphy, :stopped})
    {:noreply, %{state | running_task_ref: nil}}
  end

  def handle_info({:DOWN, ref, _, _, reason}, %{running_task_ref: ref} = state) do
    Logger.warning("Choregraphy failed with reason #{inspect(reason)}")
    RabbitManager.publish_event({:choregraphy, :stopped})
    {:noreply, %{state | running_task_ref: nil}}
  end

  def handle_info(_event, state) do
    {:noreply, state}
  end

  defp build_initial_state(state) do
    builtin_chor =
      Path.join([:code.priv_dir(:rabbit_manager), "choregraphy", "builtins.chor"])
      |> File.read!()
      |> Jason.decode!()
      |> Enum.map(&json_to_choregraphy/1)

    user_chor =
      state.choregraphy_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".chor"))
      |> Enum.reduce([], fn filename, chors ->
        chor =
          Path.join(state.choregraphy_dir, filename)
          |> File.read!()
          |> Jason.decode!()

        [json_to_choregraphy(chor) | chors]
      end)

    builtin_chor ++ user_chor
  end

  defp save_choregraphy_file(choregraphy_dir, chor) do
    str = Jason.encode!(chor |> Map.from_struct())
    filepath = Path.join(choregraphy_dir, chor.code <> ".chor")
    File.write(filepath, str)
  end

  defp delete_choregraphy_file(choregraphy_dir, chor) do
    filepath = Path.join(choregraphy_dir, chor.code <> ".chor")
    File.rm(filepath)
  end

  defp json_to_choregraphy(json) do
    %Choregraphy{
      code: json["code"],
      name: json["name"],
      actions: json["actions"]
    }
  end
end
