# Policy

Policy is an authorization management framework for Phoenix.  It aims to be
minimally invasive and secure by default.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `policy` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:policy, "~> 1.0"}]
    end
    ```

## Usage

Permissions are specified by implementing the `Policy` protocol for each
controlled entity.  Policies require two methods:

* **`permit?/3`** takes the entity in question, the current user (or `nil`), and
  the action to be taken as an atom and returns a boolean.
* **`scope/2`** takes the entity in question and the current user (or `nil`).
  It returns an Ecto query scoped to all the entities that user can view.

For example, assume we have a `Post` entity.  Users can view all posts and edit
their own posts, and admins can view and edit any post.  Furthermore, admins
can view all posts, but users can only view published posts or posts they own.

```elixir
defimpl Policy, for: Post do
  import Ecto.Query

  # First, anyone can read a post
  def permit?(_post, _user, :read), do: true
  # Second, anonymous users can't do anything else
  def permit?(_post, nil, _action), do: false
  # Third, admins can do anything
  def permit?(_post, %User{admin: true}, _action), do: true
  # Finally, users can do anything to their own posts
  def permit?(%Post{user_id: user_id}, %User{id: user_id}, _action), do: true

  # Admins can view the whole `posts` table
  def scope(_post, %User{admin: true}), do: Post
  # Anonymous users can only view public posts
  def scope(_post, nil), do: from(p in Post, where: p.published)
  # Users can view published posts and posts they own
  def scope(_post, user), do: from p in Post, where: p.published or p.user_id == ^user.id
end
```

`Policy` has a couple of implementations out of the box which allow it to be
invoked with either a bare module name or an Ecto changeset

```elixir
# These are all equivalent
Policy.permit? %Post{}, current_user, :read
Policy.permit? Post, current_user, :read
Policy.permit? Ecto.Changeset.change(%Post{}, %{}), current_user, :read
```

Bare module name permissions are determined based on the entity's default
values.  Changeset permissions are determined based on an entity with all the
proposed changes applied.

Policies are enforced at a controller level.  Controllers can import
`Policy.Helpers` to get the `:ensure_authorization` plug and the `authorize!/2`
function.

`authorize!/2` takes the `conn` and a model or list of models, throws a
`Policy.Exception` if the model (or any one of the list) is not authorized, and
returns a `conn` that is marked as authorized.

The `:ensure_authorization` plug will throw a `Policy.Exception` if a Controller
tries to send without running `authorize!/2`.

`Policy.Exception` is registered with `Plug` to return a 403 Unauthorized.

An example controller looks like this:

```elixir
defmodule MyApp.PostController do
  use MyApp.Web, :controller
  import Policy.Helpers

  alias MyApp.Post

  plug :ensure_authorization

  def index(conn, _params) do
    posts = Post
    |> Policy.scope(conn.assigns[:current_user])
    |> Repo.all

    conn = conn
    |> authorize!(posts)
    |> render("index.html", posts: posts)
  end

  def new(conn, _params) do
    changeset = Post.changeset(%Post{})

    conn
    |> authorize!(changeset)
    |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"post" => post_params}) do
    changeset = Post.changeset(%Post{}, post_params)

    conn = authorize!(conn, changeset)

    case Repo.insert(changeset) do
      {:ok, _post} ->
        conn
        |> put_flash(:info, "post created successfully.")
        |> redirect(to: post_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    post = Repo.get!(Post, id)

    conn
    |> authorize!(post)
    |> render("show.html", post: post)
  end

  def edit(conn, %{"id" => id}) do
    post = Repo.get!(Post, id)
    changeset = Post.changeset(post)

    conn
    |> authorize!(changeset)
    |> render("edit.html", post: post, changeset: changeset)
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Repo.get!(Post, id)
    changeset = Post.changeset(post, post_params)

    conn = authorize!(conn, changeset)

    case Repo.update(changeset) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "post updated successfully.")
        |> redirect(to: post_path(conn, :show, post))
      {:error, changeset} ->
        render(conn, "edit.html", post: post, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Repo.get!(Post, id)

    conn = authorize!(conn, post)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(post)

    conn
    |> put_flash(:info, "post deleted successfully.")
    |> redirect(to: post_path(conn, :index))
  end
end
```

`authorize!/2` assumes that the current user is in `conn.assigns[:current_user]`
and that the controller action is set by Phoenix.  It maps the seven RESTful
actions to `:create`, `:read`, `:update`, and `:delete`, and passes all other
actions through as-is.
