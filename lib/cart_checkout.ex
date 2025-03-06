defmodule CartCheckout do
  @moduledoc """
  High-level module for the CartCheckout application.

  This module is responsible for handling the cart and its items.
  """

  alias CartCheckout.Cart
  alias CartCheckout.Cart.Item
  alias CartCheckout.Offer

  @pricing %{
    GR1: %{
      name: "Green Tea",
      price: 3.11
    },
    SR1: %{
      name: "Strawberries",
      price: 5.00
    },
    CF1: %{
      name: "Coffee",
      price: 11.23
    }
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
end
