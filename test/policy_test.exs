defmodule PolicyTest do
  use ExUnit.Case

  defmodule MockStruct, do: defstruct []
  defimpl Policy, for: MockStruct do
    def permit?(_model, _user, _action), do: true
    def scope(_model, _user), do: raise Exception, "not implemented"
  end

  test "treats atoms like empty structs" do
    assert Policy.permit?(MockStruct, nil, :test)
  end

  test "treats ecto changesets like models"
end
