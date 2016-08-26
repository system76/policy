defmodule Policy.ExceptionTest do
  use ExUnit.Case

  test "it is an exception" do
    e = %Policy.Exception{}

    Exception.exception?(e)
  end

  test "it returns its error message" do
    try do
      raise Policy.Exception, "test message"
    rescue e ->
      assert Exception.message(e) == "test message"
    end
  end

  test "Plug treats it as a 403 Unauthorized" do
    e = %Policy.Exception{}

    assert Plug.Exception.status(e) == 403
  end
end
