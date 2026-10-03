defmodule SignalShutdownTest do
  @moduledoc false

  use ExUnit.Case, async: true

  # A dummy GenServer to stand in for Horde.DynamicSupervisorImpl.
  defmodule ImplMock do
    use GenServer

    def init(test_pid), do: {:ok, test_pid}

    def handle_call(:horde_shutting_down, _from, test_pid) do
      send(test_pid, {:horde_shutting_down, self()})
      {:reply, :ok, test_pid}
    end
  end

  test "signals every destination on shutdown" do
    {:ok, impl} = GenServer.start_link(ImplMock, self())
    {:ok, pid} = start_signal_shutdown([impl])

    assert :ok = GenServer.stop(pid)
    assert_received {:horde_shutting_down, ^impl}
  end

  test "terminates cleanly when a destination is already down" do
    {:ok, impl} = GenServer.start(ImplMock, self())
    GenServer.stop(impl)

    {:ok, pid} = start_signal_shutdown([impl, :not_registered])

    assert :ok = GenServer.stop(pid)
  end

  defp start_signal_shutdown(signal_to) do
    {:ok, pid} = GenServer.start(Horde.SignalShutdown, signal_to)
    on_exit(fn -> Process.alive?(pid) && GenServer.stop(pid) end)
    {:ok, pid}
  end
end
