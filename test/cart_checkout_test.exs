defmodule CartCheckoutTest do
  use ExUnit.Case, async: false

  alias CartCheckout.Cart
  alias CartCheckout.Cart.Item
  alias CartCheckout.Offer
  alias CartCheckout.ProductOffers

  doctest CartCheckout

  setup do
    start_supervised(ProductOffers)
    on_exit(fn -> Supervisor.terminate_child(CartCheckout.Supervisor, ProductOffers) end)
  end

  describe "new/0" do
    test "creates a new, empty cart" do
      assert %Cart{} = CartCheckout.new()
    end
  end

  describe "scan_item/3" do
    setup do
      cart = CartCheckout.new()
      %{cart: cart}
    end

    test "raises if invalid cart is not passed" do
      assert_raise FunctionClauseError, fn ->
        CartCheckout.scan_item(%{}, :GR1, 1)
      end
    end

    test "raises if invalid product code is passed", %{cart: cart} do
      assert_raise RuntimeError, fn ->
        CartCheckout.scan_item(cart, :UNKNOWN, 1)
      end
    end

    test "adds a new item to the cart with the given quantity if thers is no quanity offer for the product",
         %{cart: cart} do
      cart = CartCheckout.scan_item(cart, :CF1, 2)
      assert %Cart{items: %{CF1: %Item{purchased_quantity: 2, bonus_quantity: 0}}} = cart
    end

    test "does not add bonus quantity if minimum purchase requirement is not met", %{cart: cart} do
      ProductOffers.update(:GR1, %Offer{unit: :quantity, minimum_purchase: 2, value: 1})
      cart = CartCheckout.scan_item(cart, :GR1, 1)
      assert %Cart{items: %{GR1: %Item{purchased_quantity: 1, bonus_quantity: 0}}} = cart
    end

    test "adds bonus quanity if minimum purchase requirement is met", %{cart: cart} do
      # Add first coffee - 1 bonus
      cart = CartCheckout.scan_item(cart, :GR1, 1)
      assert %{purchased_quantity: 1, bonus_quantity: 1} = cart.items[:GR1]

      # Add second coffee - get 1 free for each (total 4)
      cart = CartCheckout.scan_item(cart, :GR1, 1)
      assert %{purchased_quantity: 2, bonus_quantity: 2} = cart.items[:GR1]

      # Add third coffee - get 3 free (total 6)
      cart = CartCheckout.scan_item(cart, :GR1, 1)
      assert %{purchased_quantity: 3, bonus_quantity: 3} = cart.items[:GR1]
    end

    test "adds bonus quanity if minimum purchase requirement is met with multiple quantities", %{
      cart: cart
    } do
      # Adding 2 at once should result in 4 (2 + 1 free for each)
      cart = CartCheckout.scan_item(cart, :GR1, 2)
      assert %{purchased_quantity: 2, bonus_quantity: 2} = cart.items[:GR1]

      # Adding 2 more should result in 6 (4 + 4 free for each)
      cart = CartCheckout.scan_item(cart, :GR1, 2)
      assert %{purchased_quantity: 4, bonus_quantity: 4} = cart.items[:GR1]
    end
  end
end
