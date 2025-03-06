defmodule CartCheckout.OfferTest do
  use ExUnit.Case, async: false

  alias CartCheckout.Offer
  alias CartCheckout.ProductOffers

  setup do
    start_supervised(ProductOffers)
    on_exit(fn -> Supervisor.terminate_child(CartCheckout.Supervisor, ProductOffers) end)
  end

  doctest Offer

  describe "calculate_bonus_quantity/2 " do
    test "calculates the bonus quantity for the product when it has quantity offer" do
      assert Offer.calculate_bonus_quantity(:GR1, 1) == 0
      assert Offer.calculate_bonus_quantity(:GR1, 2) == 1
      assert Offer.calculate_bonus_quantity(:GR1, 3) == 1
      assert Offer.calculate_bonus_quantity(:GR1, 4) == 2
    end

    test "returns zero if product does not have quantity offer" do
      assert Offer.calculate_bonus_quantity(:SR1, 1) == 0
      assert Offer.calculate_bonus_quantity(:SR1, 2) == 0
    end

    test "returns zero if minimum purchase is not met" do
      ProductOffers.update(:GR1, %Offer{unit: :quantity, minimum_purchase: 2, value: 1})
      assert Offer.calculate_bonus_quantity(:GR1, 1) == 0
      assert Offer.calculate_bonus_quantity(:GR1, 2) == 1
    end
  end
end
