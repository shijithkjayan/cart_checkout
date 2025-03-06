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

  Logic:
  1. Gets the offer for the product from ProductOffers
  2. If the offer is quantity-based (e.g., buy one get one free):
     - Checks if the total quantity meets minimum purchase requirement
     - Calculates how many complete sets of items exist (total_sets)
       For example: with min=2 and quantity=5:
       * 5 ÷ 2 = 2 complete sets
     - Multiplies complete sets by the bonus value
       * If bonus_value is 1, each set gives 1 free item
       * 2 sets × 1 bonus = 2 free items
  3. Returns 0 if:
     - No offer exists for the product
     - Offer is not quantity-based (e.g., price or percentage discount)
     - Quantity is less than minimum purchase requirement

  ## Parameters

    * `product_code` - The product code to calculate the bonus quantity for.
    * `quantity` - The quantity of the product in the cart.

  ## Examples
      # Less than minimum purchase (2), no bonus
      iex> Offer.calculate_bonus_quantity(:GR1, 1)
      0

      # One complete set (2 items), get 1 free
      iex> Offer.calculate_bonus_quantity(:GR1, 2)
      1

      # One complete set (2 items), get 1 free, 1 item leftover
      iex> Offer.calculate_bonus_quantity(:GR1, 3)
      1

      # Two complete sets, get 2 free
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
  Returns the discounted price per item.

  Logic:
  1. First checks if quantity meets minimum purchase requirement
  2. If minimum requirement is met, applies discount based on offer unit:
     - For :quantity offers (e.g., buy one get one):
       * Returns original price (discounts handled via bonus items)
     - For :price offers (e.g., £0.50 off):
       * Subtracts the fixed discount amount from original price
     - For :percent offers (e.g., 33.33% off):
       * Calculates percentage of original price
       * Subtracts that amount from original price
     - For unknown offer units:
       * Returns original price
  3. If minimum requirement not met or no valid offer:
     * Returns original price without discount

  ## Parameters

    * `mrp` - The maximum retail price of the product.
    * `offer` - The offer on the product.
    * `quantity` - The quantity of the product in the cart.

  ## Examples
      # Quantity-based offer (BOGO) - no price discount
      iex> Offer.calculate_discounted_price(3.11, %Offer{name: "Buy One Get One", minimum_purchase: 1, unit: :quantity, value: 1}, 2)
      3.11

      # Fixed price discount (£0.50 off) when buying 3 or more
      iex> Offer.calculate_discounted_price(3.11, %Offer{name: "Buy More, Pay Less", minimum_purchase: 3, unit: :price, value: 0.50}, 4)
      2.61

      # Percentage discount (33.33% off) when buying 3 or more
      iex> Offer.calculate_discounted_price(3.11, %Offer{name: "Buy More, Pay Less", minimum_purchase: 3, unit: :percent, value: 33.33}, 4)
      2.073437

      # Offer unit is unknown
      iex> Offer.calculate_discounted_price(3.11, %Offer{name: "New Offer", minimum_purchase: 3, unit: :unknown, value: 0.50}, 4)
      3.11

      # Minimum purchase not met
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
