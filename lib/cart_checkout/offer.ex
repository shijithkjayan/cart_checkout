defmodule CartCheckout.Offer do
  @moduledoc """
  This module is responsible for handling offers on products.
  """
  alias __MODULE__
  alias CartCheckout.ProductOffers

  @typedoc """
  This struct represents an offer on a product.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          unit: atom(),
          value: number(),
          minimum_purchase: integer()
        }
  defstruct [:name, :unit, :value, minimum_purchase: 1]

  @doc """
  Calculates the bonus quantity for a product based on its offer.
  Returns the number of free items to be added.

  ## Parameters

    * `product_code` - The product code to calculate the bonus quantity for.
    * `quantity` - The quantity of the product in the cart.

  ## Examples
      iex> Offer.calculate_bonus_quantity(:GR1, 1)
      0

      iex> Offer.calculate_bonus_quantity(:GR1, 2)
      1

      iex> Offer.calculate_bonus_quantity(:GR1, 3)
      1

      iex> Offer.calculate_bonus_quantity(:GR1, 4)
      2
  """
  @spec calculate_bonus_quantity(atom(), integer()) :: integer()
  def calculate_bonus_quantity(product_code, quantity) do
    case ProductOffers.get(product_code) do
      %Offer{unit: :quantity, minimum_purchase: min, value: bonus_value} when quantity >= min ->
        total_sets = div(quantity, min)
        bonus_value * total_sets

      _ ->
        0
    end
  end

  @doc """
  Calculates the discounted price for a product based on its offer.
  Returns the discounted price.

  ## Parameters

    * `mrp` - The maximum retail price of the product.
    * `offer` - The offer on the product.
    * `quantity` - The quantity of the product in the cart.

  ## Examples
      # No discount as the offer is for quantity
      iex> Offer.calculate_discounted_price(3.11, %Offer{name: "Buy One Get One", minimum_purchase: 1, unit: :quantity, value: 1}, 2)
      3.11

      # Price discount
      iex> Offer.calculate_discounted_price(3.11, %Offer{name: "Buy More, Pay Less", minimum_purchase: 3, unit: :price, value: 0.50}, 4)
      2.61

      # Percent discount
      iex> Offer.calculate_discounted_price(3.11, %Offer{name: "Buy More, Pay Less", minimum_purchase: 3, unit: :percent, value: 33.33}, 4)
      2.073437

      # No unit of the offer is unknown
      iex> Offer.calculate_discounted_price(3.11, %Offer{name: "New Offer", minimum_purchase: 3, unit: :unknown, value: 0.50}, 4)
      3.11

      # No discount as the quantity is less than the minimum purchase
      iex> Offer.calculate_discounted_price(3.11, %Offer{name: "Buy More, Pay Less", minimum_purchase: 3, unit: :price, value: 0.50}, 2)
      3.11
  """
  @spec calculate_discounted_price(float(), Offer.t(), integer()) :: number()
  def calculate_discounted_price(mrp, %Offer{minimum_purchase: min} = offer, quantity)
      when quantity >= min do
    case offer.unit do
      :quantity -> mrp
      :price -> apply_price_discount(mrp, offer)
      :percent -> apply_percent_discount(mrp, offer)
      _ -> mrp
    end
  end

  def calculate_discounted_price(mrp, _offer, _quantity), do: mrp

  defp apply_percent_discount(mrp, %Offer{value: value}) do
    mrp - mrp * value / 100
  end

  defp apply_price_discount(mrp, %Offer{value: value}) do
    # Convert to float
    (mrp - value) * 1.0
  end
end
