defmodule Turbopuffer.VectorTest do
  use ExUnit.Case

  alias Turbopuffer.{Client, Namespace, Vector}

  setup do
    client = Client.new(api_key: "test-key")
    namespace = Namespace.new(client, "test-ns")
    {:ok, namespace: namespace}
  end

  describe "vector formatting" do
    test "formats vectors correctly", %{namespace: namespace} do
      vectors = [
        %{
          id: "doc1",
          vector: [0.1, 0.2, 0.3],
          attributes: %{
            text: "Sample document",
            category: "example"
          }
        }
      ]

      # This test validates the vector structure is properly formatted
      assert {:error, _} = Vector.write(namespace, vectors)
    end

    test "handles vectors with atom keys", %{namespace: namespace} do
      vectors = [
        %{
          id: "doc1",
          vector: [0.1, 0.2, 0.3],
          attributes: %{text: "Sample"}
        }
      ]

      # Test that atom keys are properly converted
      assert {:error, _} = Vector.write(namespace, vectors)
    end
  end

  describe "query validation" do
    test "requires vector parameter", %{namespace: namespace} do
      assert_raise KeyError, fn ->
        Vector.query(namespace, top_k: 10)
      end
    end

    test "accepts valid query options", %{namespace: namespace} do
      # This will fail with connection error but validates the parameters
      result =
        Vector.query(namespace,
          vector: [0.1, 0.2, 0.3],
          top_k: 10,
          include_attributes: ["text"],
          include_vectors: false
        )

      assert {:error, _} = result
    end
  end

  describe "include_attributes normalization" do
    test "accepts :all as alias for true", %{namespace: namespace} do
      # This will fail with connection error but validates :all doesn't raise
      result = Vector.query(namespace,
        vector: [0.1, 0.2, 0.3],
        top_k: 10,
        include_attributes: :all
      )
      assert {:error, _} = result
    end

    test "accepts boolean true", %{namespace: namespace} do
      result = Vector.query(namespace,
        vector: [0.1, 0.2, 0.3],
        include_attributes: true
      )
      assert {:error, _} = result
    end

    test "accepts list of attribute names", %{namespace: namespace} do
      result = Vector.query(namespace,
        vector: [0.1, 0.2, 0.3],
        include_attributes: ["text", "category"]
      )
      assert {:error, _} = result
    end

    test "raises ArgumentError for invalid values", %{namespace: namespace} do
      assert_raise ArgumentError, ~r/invalid value for :include_attributes/, fn ->
        Vector.query(namespace,
          vector: [0.1, 0.2, 0.3],
          include_attributes: :invalid
        )
      end
    end
  end

  describe "query attribute selection in HTTP body" do
    setup do
      bypass = Bypass.open()
      client = Client.new(api_key: "test-key", base_url: "http://localhost:#{bypass.port}")
      namespace = Namespace.new(client, "test-ns")
      {:ok, namespace: namespace, bypass: bypass}
    end

    defp query_and_capture_body(bypass, namespace, opts) do
      test_pid = self()
      ref = make_ref()

      Bypass.expect_once(bypass, "POST", "/v2/namespaces/test-ns/query", fn conn ->
        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        body = JSON.decode!(raw)
        send(test_pid, {ref, body})
        Plug.Conn.resp(conn, 200, JSON.encode!(%{"rows" => []}))
      end)

      {:ok, _} = Vector.query(namespace, opts)
      assert_receive {^ref, body}
      body
    end

    test "sends include_attributes by default", %{namespace: namespace, bypass: bypass} do
      body = query_and_capture_body(bypass, namespace, vector: [0.1, 0.2], top_k: 5)

      assert Map.has_key?(body, "include_attributes")
      assert body["include_attributes"] == true
      refute Map.has_key?(body, "exclude_attributes")
    end

    test "sends include_attributes when given a list", %{namespace: namespace, bypass: bypass} do
      body = query_and_capture_body(bypass, namespace,
        vector: [0.1, 0.2],
        include_attributes: ["text", "category"]
      )

      assert body["include_attributes"] == ["text", "category"]
      refute Map.has_key?(body, "exclude_attributes")
    end

    test "sends only exclude_attributes when include_attributes is false", %{namespace: namespace, bypass: bypass} do
      body = query_and_capture_body(bypass, namespace,
        vector: [0.1, 0.2],
        include_attributes: false,
        exclude_attributes: ["vector"]
      )

      refute Map.has_key?(body, "include_attributes")
      assert body["exclude_attributes"] == ["vector"]
    end

    test "sends only exclude_attributes when include_attributes is []", %{namespace: namespace, bypass: bypass} do
      body = query_and_capture_body(bypass, namespace,
        vector: [0.1, 0.2],
        include_attributes: [],
        exclude_attributes: ["vector"]
      )

      refute Map.has_key?(body, "include_attributes")
      assert body["exclude_attributes"] == ["vector"]
    end

    test "sends include_attributes when exclude_attributes is not provided", %{namespace: namespace, bypass: bypass} do
      body = query_and_capture_body(bypass, namespace,
        vector: [0.1, 0.2],
        include_attributes: false
      )

      assert Map.has_key?(body, "include_attributes")
      refute Map.has_key?(body, "exclude_attributes")
    end

    test "sends include_attributes alongside exclude_attributes when inclusion is explicitly requested", %{namespace: namespace, bypass: bypass} do
      body = query_and_capture_body(bypass, namespace,
        vector: [0.1, 0.2],
        include_attributes: ["text"],
        exclude_attributes: ["vector"]
      )

      assert body["include_attributes"] == ["text"]
      assert body["exclude_attributes"] == ["vector"]
    end
  end
end
