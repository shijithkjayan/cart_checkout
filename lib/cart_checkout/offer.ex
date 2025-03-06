defmodule CartCheckout.Offer do
  @moduledoc """
  This module is responsible for handling offers on products.
  """

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
end
