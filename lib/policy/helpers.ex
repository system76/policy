defmodule Policy.Helpers do
  import Plug.Conn

  def ensure_authorization(conn, _opts) do
    register_before_send conn, fn (after_conn) ->
      unless after_conn.private[:policy_authorized] do
        raise Policy.Exception, message: "no authentication run"
      end

      after_conn
    end
  end

  def authorize!(conn, models) when is_list(models) do
    Enum.each(models, &authorize!(conn, &1))

    conn |> mark_authorized
  end
  def authorize!(conn, model) do
    action = action_for(conn)
    current_user = conn.assigns[:current_user]

    unless Policy.permit?(model, current_user, action) do
      raise Policy.Exception, message: "not authorized"
    end

    conn |> mark_authorized
  end

  defp action_for(conn) do
    case Phoenix.Controller.action_name(conn) do
      action when action == :new            -> :create
      action when action in [:index, :show] -> :read
      action when action == :edit           -> :update
      action                                -> action
    end
  end

  defp mark_authorized(conn), do: put_private(conn, :policy_authorized, true)
end
