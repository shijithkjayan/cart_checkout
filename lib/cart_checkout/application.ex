defmodule CartCheckout.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CartCheckout.ProductOffers
    ]

    opts = [strategy: :one_for_one, name: CartCheckout.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
