defmodule CartCheckout.Cart do
  @moduledoc """
  This module is responsible for handling the cart and its items.
  """

  @typedoc """
  This struct represents a cart.
  The product code is the key and the value is an `Item`.
  """
  @type t :: %__MODULE__{
          items: map()
        }
  defstruct items: %{}

  defmodule Item do
    @moduledoc """
    Module to represent an item in the cart.
    """

    @typedoc """
    This struct represents an item in the cart.
    It has a single field `quantity` which represents the quantity of the item.
    """
    @type t :: %__MODULE__{
            purchased_quantity: integer(),
            bonus_quantity: integer()
          }
    defstruct purchased_quantity: 0, bonus_quantity: 0
  end
end
