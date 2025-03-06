defmodule CartCheckout do
  @moduledoc """
  High-level module for the CartCheckout application.

  This module is responsible for handling the cart and its items.
  """

  alias CartCheckout.Cart
  alias CartCheckout.Cart.Item
  alias CartCheckout.Offer
  alias CartCheckout.ProductOffers

  @pricing %{
    GR1: 3.11,
    SR1: 5.00,
    CF1: 11.23
  }

  @product_codes Map.keys(@pricing)

  @doc """
  Creates a new, empty cart.

  ## Examples

      iex> CartCheckout.new()
      %Cart{}
  """
  @spec new() :: Cart.t()
  def new, do: %Cart{}

  @spec scan_item(Cart.t(), atom(), integer()) :: Cart.t()
  def scan_item(%Cart{items: items}, product_code, quantity)
      when product_code in @product_codes do
    {_, items} =
      Map.get_and_update(items, product_code, fn
        nil ->
          bonus_quantity = Offer.calculate_bonus_quantity(product_code, quantity)

          {nil,
           %Item{purchased_quantity: quantity - bonus_quantity, bonus_quantity: bonus_quantity}}

        item ->
          total_quantity = item.purchased_quantity + item.bonus_quantity + quantity
          bonus_quantity = Offer.calculate_bonus_quantity(product_code, total_quantity)

          {item,
           %Item{
             purchased_quantity: total_quantity - bonus_quantity,
             bonus_quantity: bonus_quantity
           }}
      end)

    %Cart{items: items}
  end

  def scan_item(_, product_code, _) when product_code not in @product_codes,
    do: raise("Invalid product code: #{product_code}")

  @doc """
  Calculates the total cost of the cart after applying discounts.

  ## Examples

      iex> cart = CartCheckout.new()
      ...> |> CartCheckout.scan_item(:GR1, 1)
      ...> |> CartCheckout.scan_item(:CF1, 1)
      ...> |> CartCheckout.scan_item(:GR1, 3)
      iex> CartCheckout.checkout(cart)
      17.45
  """
  @spec checkout(Cart.t()) :: float()
  def checkout(%Cart{items: items}) do
    items
    |> Enum.reduce(0.0, fn {product_code, item}, total ->
      mrp = Map.get(@pricing, product_code)
      discounted_price_per_purchased_item = get_discounted_price(mrp, product_code, item)
      final_price = discounted_price_per_purchased_item * item.purchased_quantity

      total + final_price
    end)
    |> Float.round(2)
  end

  def checkout(_), do: raise("Invalid cart")

  # Private functions
  defp get_discounted_price(mrp, product_code, %Item{purchased_quantity: quantity}) do
    offer = ProductOffers.get(product_code)
    Offer.calculate_discounted_price(mrp, offer, quantity)
  end
end
