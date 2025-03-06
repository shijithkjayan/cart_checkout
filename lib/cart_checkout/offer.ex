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
      1

      iex> Offer.calculate_bonus_quantity(:GR1, 2)
      2
  """
  @spec calculate_bonus_quantity(atom(), integer()) :: integer()
  def calculate_bonus_quantity(product_code, quantity) do
    case ProductOffers.get(product_code) do
      %Offer{unit: :quantity, minimum_purchase: min, value: bonus_value} when quantity >= min ->
        bonus_sets = div(quantity, min)
        bonus_sets * trunc(bonus_value)

      _ ->
        0
    end
  end
end
