defmodule PresencemediaWeb.PageController do
  use PresencemediaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
