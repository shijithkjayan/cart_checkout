defmodule CartCheckout.ProductOffersTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias CartCheckout.Offer
  alias CartCheckout.ProductOffers

  setup do
    start_supervised(ProductOffers)
    on_exit(fn -> Supervisor.terminate_child(CartCheckout.Supervisor, ProductOffers) end)
  end

  doctest ProductOffers

  test "starts the agent with base offers" do
    assert %Offer{
             name: "Buy One Get One",
             minimum_purchase: 2,
             unit: :quantity,
             value: 1
           } == ProductOffers.get(:GR1)

    assert %Offer{
             name: "Buy More, Pay Less",
             minimum_purchase: 3,
             unit: :price,
             value: 0.50
           } == ProductOffers.get(:SR1)

    assert %Offer{
             name: "Buy More, Pay Less",
             minimum_purchase: 3,
             unit: :percent,
             value: 33.33
           } == ProductOffers.get(:CF1)
  end

  describe "get/1" do
    test "returns the offer for a product" do
      offer = %Offer{
        name: "Buy One Get One",
        minimum_purchase: 2,
        unit: :quantity,
        value: 1
      }

      assert offer == ProductOffers.get(:GR1)
    end

    test "returns nil for an unknown product" do
      assert nil == ProductOffers.get(:UNKNOWN)
    end
  end

  describe "update/2" do
    test "updates the offer for a product" do
      offer = %Offer{
        name: "Buy More, Pay Less",
        minimum_purchase: 2,
        unit: :price,
        value: 1.00
      }

      assert :ok == ProductOffers.update(:GR1, offer)
      assert offer == ProductOffers.get(:GR1)
    end

    test "logs an error for an invalid minimum purchase" do
      offer = %Offer{
        name: "Buy More, Pay Less",
        minimum_purchase: -1,
        unit: :price,
        value: 1.00
      }

      {result, log} = with_log(fn -> ProductOffers.update(:GR1, offer) end)

      assert :ok == result
      assert log =~ "Minimum purchase and value should be greater than 0, got: #{inspect(offer)}"
    end

    test "logs an error for an invalid value" do
      offer = %Offer{
        name: "Buy More, Pay Less",
        minimum_purchase: 2,
        unit: :price,
        value: -1.00
      }

      {result, log} = with_log(fn -> ProductOffers.update(:GR1, offer) end)

      assert :ok == result
      assert log =~ "Minimum purchase and value should be greater than 0, got: #{inspect(offer)}"
    end

    test "logs an error for an invalid offer" do
      offer = %{
        name: "Buy More, Pay Less",
        minimum_purchase: 2,
        unit: :price,
        value: 1.00
      }

      {result, log} = with_log(fn -> ProductOffers.update(:GR1, offer) end)

      assert :ok == result
      assert log =~ "Offer must be an Offer struct, got: #{inspect(offer)}"
    end
  end
end
