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

  describe "calculate_discounted_price/2" do
    test "calculates the bonus price for the product when it has price offer and meets minimum required purchase" do
      offer = %Offer{minimum_purchase: 3, unit: :price, value: 0.50}
      assert Offer.calculate_discounted_price(5, offer, 1) == 5.0
      assert Offer.calculate_discounted_price(5, offer, 2) == 5.0
      assert Offer.calculate_discounted_price(5, offer, 3) == 4.50
      assert Offer.calculate_discounted_price(5, offer, 4) == 4.50
    end

    test "calculates the bonus price for the product whtn it has percentage offer and meets minimum required purchase" do
      offer = %Offer{minimum_purchase: 3, unit: :percent, value: 25.0}
      assert Offer.calculate_discounted_price(100, offer, 1) == 100
      assert Offer.calculate_discounted_price(100, offer, 2) == 100
      assert Offer.calculate_discounted_price(100, offer, 3) == 75.0
    end

    test "returns MRP if the product has quantity offer" do
      offer = %Offer{minimum_purchase: 1, unit: :quantity, value: 1}
      assert Offer.calculate_discounted_price(3.11, offer, 1) == 3.11
      assert Offer.calculate_discounted_price(3.11, offer, 2) == 3.11
    end

    test "returns MRP if the product has unknown offer unit" do
      offer = %Offer{minimum_purchase: 1, unit: :new, value: 4}

      assert Offer.calculate_discounted_price(3.11, offer, 3) == 3.11
    end

    test "returns MRP if the minimum purchase is not met" do
      offer = %Offer{minimum_purchase: 3, unit: :price, value: 0.50}
      assert Offer.calculate_discounted_price(3.11, offer, 2) == 3.11
    end
  end
end
