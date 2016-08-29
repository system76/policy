defmodule Policy.HelpersTest do
  use ExUnit.Case

  defmodule MockStruct do
    defstruct permit: false
  end

  defimpl Policy, for: MockStruct do
    def permit?(model, _user, _action), do: model.permit
    def scope(_model, _user), do: raise Exception, "not implemented"
  end

  setup do
    conn = Plug.Test.conn(:get, "/")
    |> Plug.Conn.put_private(:phoenix_action, :index)
    # TODO: Remove dependency on Phoenix action

    {:ok, conn: conn}
  end

  test "authorizing a nonpermitted action raises an exception", %{conn: conn} do
    assert_raise Policy.Exception, fn ->
      Policy.Helpers.authorize!(conn, %MockStruct{permit: false})
    end
  end

  test "authorizing a permitted action does not raise an exception", %{conn: conn} do
    try do
      Policy.Helpers.authorize!(conn, %MockStruct{permit: true})
    rescue _e ->
      flunk "exception raised"
    end
  end

  test "failing to authorize after ensure authorization is run raises an exception", %{conn: conn} do
    assert_raise Policy.Exception, fn ->
      conn
      |> Policy.Helpers.ensure_authorization(%{})
      |> Plug.Conn.send_resp(200, "Hello, World!")
    end
  end
end
