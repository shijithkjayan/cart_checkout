defmodule CartCheckoutTest do
  use ExUnit.Case

  alias CartCheckout.Cart

  doctest CartCheckout

  describe "new/0" do
    test "creates a new, empty cart" do
      assert %Cart{} = CartCheckout.new()
    end
  end
end
