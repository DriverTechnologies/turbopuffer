defmodule Turbopuffer.NamespaceTest do
  use ExUnit.Case

  alias Turbopuffer.{Client, Namespace}

  setup do
    client = Client.new(api_key: "test-key")
    {:ok, client: client}
  end

  describe "list/2" do
    test "builds path without query params", %{client: client} do
      assert {:error, _} = Namespace.list(client)
    end

    test "builds path with prefix", %{client: client} do
      assert {:error, _} = Namespace.list(client, prefix: "prod-")
    end

    test "builds path with all options", %{client: client} do
      assert {:error, _} = Namespace.list(client, prefix: "test-", page_size: 50, cursor: "next")
    end
  end
end
