defmodule CartCheckout.ProductOffers do
  @moduledoc """
  This module is responsible for managing the product offers.

  Offers are stored in an Agent and can be retrieved and updated.
  This makes it easier to update the offers on the fly.
  """
  use Agent

  require Logger

  alias CartCheckout.Offer

  @base_offers %{
    GR1: %Offer{
      name: "Buy One Get One",
      minimum_purchase: 2,
      unit: :quantity,
      value: 1
    },
    SR1: %Offer{
      name: "Buy More, Pay Less",
      minimum_purchase: 3,
      unit: :price,
      value: 0.50
    },
    CF1: %Offer{
      name: "Buy More, Pay Less",
      minimum_purchase: 3,
      unit: :percent,
      value: 33.33
    }
  }

  @doc """
  Starts the agent with the base offers.
  """
  @spec start_link(any()) :: {:ok, pid()} | {:error, term()}
  def start_link(_opts) do
    Agent.start_link(fn -> @base_offers end, name: __MODULE__)
  end

  @doc """
  Retrieves the offer for a product code. Returns nil if the product code is unknown.

  ## Parameters

    * `product_code` - The product code to retrieve the offer for.

  ## Examples

      iex> ProductOffers.get(:GR1)
      %Offer{name: "Buy One Get One", minimum_purchase: 2, unit: :quantity, value: 1}

      iex> ProductOffers.get(:UNKNOWN)
      nil
  """
  @spec get(String.t()) :: Offer.t() | nil
  def get(product_code) do
    Agent.get(__MODULE__, fn offers -> Map.get(offers, product_code) end)
  end

  @doc """
  Updates the offer for a product code. Expects an Offer struct.
  If the given offer is not an Offer struct, it will log an error.

  ## Parameters

    * `product_code` - The product code to update the offer for.
    * `offer` - The new offer to set. Expects an Offer struct.

  ## Examples

      iex> ProductOffers.update(:GR1, %Offer{name: "Buy More, Pay Less", minimum_purchase: 3, unit: :price, value: 1})
      :ok

      iex> ProductOffers.update(:GR1, %{name: "Buy More, Pay Less", minimum_purchase: 3, unit: :price, value: 1})
      :ok
  """
  @spec update(String.t(), Offer.t()) :: :ok
  def update(product_code, %Offer{} = offer) do
    Agent.update(__MODULE__, fn offers -> Map.put(offers, product_code, offer) end)
  end

  def update(_product_code, offer) do
    Logger.error("Offer must be an Offer struct, got: #{inspect(offer)}")
    :ok
  end
end
