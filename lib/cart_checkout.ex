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

  @doc """
  Scans an item and adds it to the cart.
  Checks if the product has a quantity offer and calculates any bonus items.

  The total quantity in the cart is split between purchased and bonus quantities:
  - For new items: If adding 2 items triggers a "buy one get one free" offer,
    it will store 1 as purchased_quantity and 1 as bonus_quantity
  - For existing items: Recalculates the split based on the new total.
    For example, with "buy one get one free":
    * Adding 1 item: 1 purchased, 0 bonus
    * Adding 1 more: 1 purchased, 1 bonus (total 2)
    * Adding 1 more: 2 purchased, 1 bonus (total 3)
    * Adding 1 more: 2 purchased, 2 bonus (total 4)

  Raises an error if the product code is invalid or if the cart is invalid.

  ## Examples

      iex> CartCheckout.new()
      ...> |> CartCheckout.scan_item(:GR1, 1)
      %Cart{items: %{GR1: %Item{purchased_quantity: 1, bonus_quantity: 0}}}

      iex> CartCheckout.new()
      ...> |> CartCheckout.scan_item(:GR1, 1)
      ...> |> CartCheckout.scan_item(:GR1, 1)
      %Cart{items: %{GR1: %Item{purchased_quantity: 1, bonus_quantity: 1}}}
  """
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

  The total calculation process:
  1. For each item in the cart:
     - Gets the item's base price (MRP)
     - Checks if there's a price-based offer (fixed price or percentage discount)
     - Calculates the discounted price per item
     - Multiplies the discounted price by the purchased quantity only
       (bonus items are free)
  2. Sums up all item totals
  3. Rounds the final amount to 2 decimal places

  For example:
  - Green tea (GR1) at £3.11: Buy one get one free
    * Buying 3 = 2 purchased (£6.22) + 1 bonus (free) = £6.22
  - Strawberries (SR1) at £5.00: Buy 3 or more and pay £4.50 each
    * Buying 3 = 3 purchased at £4.50 each = £13.50
  - Coffee (CF1) at £11.23: Buy 3 or more and get 33.33% off
    * Buying 3 = 3 purchased at £7.49 each = £22.47

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
