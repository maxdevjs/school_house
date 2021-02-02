defmodule Elixirschool.Repo do
  use Ecto.Repo,
    otp_app: :elixirschool,
    adapter: Ecto.Adapters.Postgres
end
