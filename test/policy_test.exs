defmodule PolicyTest do
  use ExUnit.Case

  defmodule MockSchema do
    use Ecto.Schema
    schema "test" do end
  end

  defimpl Policy, for: MockSchema do
    def permit?(_model, _user, _action), do: true
    def scope(_model, _user), do: raise Exception, "not implemented"
  end

  test "treats atoms like empty structs" do
    assert Policy.permit?(MockSchema, nil, :test)
  end

  test "treats ecto changesets like models" do
    changeset = Ecto.Changeset.change(%MockSchema{}, %{})
    assert Policy.permit?(changeset, nil, :test)
  end
end
