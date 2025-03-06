defmodule CartCheckout do
  @moduledoc """
  High-level module for the CartCheckout application.

  This module is responsible for handling the cart and its items.
  """

  alias CartCheckout.Cart

  @doc """
  Creates a new, empty cart.

  ## Examples

      iex> CartCheckout.new()
      %Cart{}
  """
  @spec new() :: Cart.t()
  def new, do: %Cart{}
end
