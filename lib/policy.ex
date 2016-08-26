defprotocol Policy do
  @moduledoc """
  Policies provide a unified authorization system for our Ecto models.
  """

  @doc """
  Returns true if the user can take the action specified on the model provided.
  """
  @spec permit?(Policy.t, Hal.User.t | nil, atom) :: boolean
  def permit?(model, user \\ nil, action)

  @doc """
  Returns an ecto query scoped to the legal models for the user.
  """
  @spec scope(Policy.t, Hal.User.t | nil) :: Ecto.Query.t
  def scope(model, user \\ nil)
end



defimpl Policy, for: Atom do
  @moduledoc """
  Allows use with a bare model name instead of an empty struct.
  """

  def permit?(model, user, action),
    do: Policy.permit?(struct(model), user, action)

  def scope(model, user), do: Policy.scope(struct(model), user)
end



defimpl Policy, for: Ecto.Changeset do
  @moduledoc """
  Allows use with an Ecto.Changeset as though it were a model.
  """

  def permit?(changeset, user, action) do
    changeset
    |> Ecto.Changeset.apply_changes
    |> Policy.permit?(user, action)
  end

  def scope(changeset, user) do
    changeset
    |> Ecto.Changeset.apply_changes
    |> Policy.scope(user)
  end
end
