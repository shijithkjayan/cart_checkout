# CartCheckout

A shopping cart implementation that handles product checkout and applies special offers.

## Features
- Add products to cart
- Calculate total price
- Apply special offers and discounts
- Support for multiple offer types
- Extensible architecture

## Installation
1. Clone the repository
```bash
git clone git@github.com:shijithkjayan/cart_checkout.git
cd cart_checkout
```

2. Install dependencies
```bash
mix deps.get
```

## Usage
1. Start the application
```bash
iex -S mix
```

2. Run tests
```bash
mix test
```

or run tests in watch mode

```bash
mix test.watch
```

3. Example usage
```elixir
cart = CartCheckout.new()
cart = CartCheckout.scan_item(cart, :GR1, 2)
cart = CartCheckout.scan_item(cart, :CF1, 1)
cart = CartCheckout.scan_item(cart, :GR1, 1)
cart = CartCheckout.scan_item(cart, :CF1, 2)

CartCheckout.checkout(cart)
```

## Architecture
The project uses a clean architecture approach with:
- Cart: Manages products and quantities
- Checkout: Handles price calculations
- Offer Agent: Stores and applies special offers
- Product Catalog: Maintains product information

## Why Agent Pattern for Offers?
The Agent pattern is used for managing offers because:
1. Separation of Concerns: Isolates offer logic from cart management
2. Flexibility: Easy to add/modify offers without changing core cart logic, and allows for dynamic offer updates
3. Maintainability: Offers can be managed independently
4. Scalability: New offer types can be added without modifying existing code

## Additional Features
Potential enhancements that could be added:
1. Reduce quantity of products in cart
2. Remove products from cart
3. Clear entire cart


