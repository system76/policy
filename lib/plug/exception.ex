defimpl Plug.Exception, for: Policy.Exception do
  def status(_exception), do: 403
end
