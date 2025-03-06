defmodule CartCheckoutTest do
  use ExUnit.Case, async: false

  alias CartCheckout.Cart
  alias CartCheckout.Cart.Item
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
      cart = CartCheckout.scan_item(cart, :GR1, 1)
      assert %Cart{items: %{GR1: %Item{purchased_quantity: 1, bonus_quantity: 0}}} = cart
    end

    test "adds bonus quanity if minimum purchase requirement is met", %{cart: cart} do
      cart = CartCheckout.scan_item(cart, :GR1, 1)
      assert %Cart{items: %{GR1: %Item{purchased_quantity: 1, bonus_quantity: 0}}} = cart

      # Add second Green teas - 1 bonus
      cart = CartCheckout.scan_item(cart, :GR1, 1)
      assert %{purchased_quantity: 1, bonus_quantity: 1} = cart.items[:GR1]

      # Add third Green teas - 1 bonus (total 3)
      cart = CartCheckout.scan_item(cart, :GR1, 1)
      assert %{purchased_quantity: 2, bonus_quantity: 1} = cart.items[:GR1]

      # Add fourth Green teas - get 2 free (total 4)
      cart = CartCheckout.scan_item(cart, :GR1, 1)
      assert %{purchased_quantity: 2, bonus_quantity: 2} = cart.items[:GR1]
    end

    test "adds bonus quanity if minimum purchase requirement is met with multiple quantities", %{
      cart: cart
    } do
      # Adding 2 at once should result in 1 bonus quantity
      cart = CartCheckout.scan_item(cart, :GR1, 2)
      assert %{purchased_quantity: 1, bonus_quantity: 1} = cart.items[:GR1]

      # Adding 2 more should result in 2 bonus quantity
      cart = CartCheckout.scan_item(cart, :GR1, 2)
      assert %{purchased_quantity: 2, bonus_quantity: 2} = cart.items[:GR1]
    end
  end

  describe "checkout/1" do
    test "raises if invalid cart is passed" do
      assert_raise RuntimeError, fn ->
        CartCheckout.checkout(%{})
      end
    end

    test "returns the total cost of the cart after applying discounts" do
      cart =
        CartCheckout.new()
        |> CartCheckout.scan_item(:GR1, 1)
        |> CartCheckout.scan_item(:SR1, 1)
        |> CartCheckout.scan_item(:GR1, 1)
        |> CartCheckout.scan_item(:GR1, 1)
        |> CartCheckout.scan_item(:CF1, 1)

      assert CartCheckout.checkout(cart) == 22.45

      cart =
        CartCheckout.new()
        |> CartCheckout.scan_item(:GR1, 1)
        |> CartCheckout.scan_item(:GR1, 1)

      assert CartCheckout.checkout(cart) == 3.11

      cart =
        CartCheckout.new()
        |> CartCheckout.scan_item(:SR1, 1)
        |> CartCheckout.scan_item(:SR1, 1)
        |> CartCheckout.scan_item(:GR1, 1)
        |> CartCheckout.scan_item(:SR1, 1)

      assert CartCheckout.checkout(cart) == 16.61

      cart =
        CartCheckout.new()
        |> CartCheckout.scan_item(:GR1, 1)
        |> CartCheckout.scan_item(:CF1, 1)
        |> CartCheckout.scan_item(:SR1, 1)
        |> CartCheckout.scan_item(:CF1, 1)
        |> CartCheckout.scan_item(:CF1, 1)

      assert CartCheckout.checkout(cart) == 30.57
    end

    test "returns zero if cart is empty" do
      cart = CartCheckout.new()
      assert CartCheckout.checkout(cart) == 0
    end
  end
end
