defmodule Phoenix.LiveView.CommandTest do
  use ExUnit.Case, async: true

  describe "parameter validation" do
    test "ensures params is a map" do
      # These should work without error - they test parameter conversion only
      Phoenix.LiveView.send_command(self(), :test, %{key: "value"})
      Phoenix.LiveView.send_command(self(), :test, [key: "value"])  # Gets converted to map
      Phoenix.LiveView.send_command(self(), :test)  # Uses default empty map
    end

    test "validates command is atom" do
      assert_raise FunctionClauseError, fn ->
        Phoenix.LiveView.send_command(self(), "invalid_command", %{})
      end
    end

    test "validates destination types" do
      # These should work
      Phoenix.LiveView.send_command(nil, :test, %{})  # nil -> self()
      Phoenix.LiveView.send_command(self(), :test, %{})  # pid
      Phoenix.LiveView.send_command({SomeModule, "id"}, :test, %{})  # {module, id}
      Phoenix.LiveView.send_command(%Phoenix.LiveComponent.CID{cid: 1}, :test, %{})  # CID

      # Invalid destinations should raise
      assert_raise FunctionClauseError, fn ->
        Phoenix.LiveView.send_command("invalid", :test, %{})
      end
    end
  end

  describe "send_command message format" do
    test "sends correct message format to LiveView" do
      test_pid = self()
      Phoenix.LiveView.send_command(test_pid, :test_command, %{data: "test"})
      
      assert_receive {:phoenix, :send_command, {:test_command, %{data: "test"}}}
    end

    test "sends correct message format to LiveComponent" do
      Phoenix.LiveView.send_command({TestModule, "test-id"}, :component_cmd, %{value: 123})
      
      assert_receive {:phoenix, :send_command_to_component, {{TestModule, "test-id"}, :component_cmd, %{value: 123}}}
    end

    test "sends correct message format to LiveComponent with CID" do
      cid = %Phoenix.LiveComponent.CID{cid: 42}
      Phoenix.LiveView.send_command(cid, :cid_cmd, %{test: true})
      
      assert_receive {:phoenix, :send_command_to_component, {^cid, :cid_cmd, %{test: true}}}
    end
  end

  describe "handle_command callbacks" do
    test "callback definition exists for LiveView" do
      assert function_exported?(Phoenix.LiveView, :behaviour_info, 1)
      callbacks = Phoenix.LiveView.behaviour_info(:callbacks)
      assert Enum.member?(callbacks, {:handle_command, 3})
    end

    test "callback definition exists for LiveComponent" do
      assert function_exported?(Phoenix.LiveComponent, :behaviour_info, 1)
      callbacks = Phoenix.LiveComponent.behaviour_info(:callbacks)
      assert Enum.member?(callbacks, {:handle_command, 3})
    end

    test "handle_command is optional callback for LiveView" do
      optional_callbacks = Phoenix.LiveView.behaviour_info(:optional_callbacks)
      assert Enum.member?(optional_callbacks, {:handle_command, 3})
    end

    test "handle_command is optional callback for LiveComponent" do
      optional_callbacks = Phoenix.LiveComponent.behaviour_info(:optional_callbacks)
      assert Enum.member?(optional_callbacks, {:handle_command, 3})
    end
  end
end