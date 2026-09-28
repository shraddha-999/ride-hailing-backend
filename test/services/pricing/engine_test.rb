require "test_helper"

class PricingEngineTest < Minitest::Test
  def engine = Pricing::Engine.new

  def hatchback = CarType.fetch(:hatchback)

  def percent(value, **opts) = Coupon.new(code: "P", kind: :percent, value: value, **opts)

  def flat(value) = Coupon.new(code: "F", kind: :flat, value: value)

  def test_quote_without_coupon
    quote = engine.quote(car_type: hatchback, distance_km: 10)
    assert_equal bd(69), quote.base_fare
    assert_equal bd(0), quote.discount
    assert_equal bd(69), quote.total
    assert_nil quote.coupon_code
  end

  def test_percent_coupon
    quote = engine.quote(car_type: hatchback, distance_km: 10, coupon: percent(10))
    assert_equal bd("6.9"), quote.discount
    assert_equal bd("62.1"), quote.total
    assert_equal "P", quote.coupon_code
  end

  def test_percent_coupon_respects_max_discount
    quote = engine.quote(car_type: hatchback, distance_km: 10, coupon: percent(50, max_discount: 20))
    assert_equal bd(20), quote.discount
    assert_equal bd(49), quote.total
  end

  def test_flat_coupon
    quote = engine.quote(car_type: hatchback, distance_km: 10, coupon: flat(20))
    assert_equal bd(49), quote.total
  end

  def test_coupon_never_takes_fare_below_zero
    quote = engine.quote(car_type: hatchback, distance_km: 10, coupon: flat(500))
    assert_equal bd(69), quote.discount
    assert_equal bd(0), quote.total
  end

  def test_coupon_applies_after_minimum_fare
    # 1 km = 10, floored to 50, THEN 20 off -> 30 (documented decision)
    quote = engine.quote(car_type: hatchback, distance_km: 1, coupon: flat(20))
    assert_equal bd(50), quote.base_fare
    assert_equal bd(30), quote.total
  end

  def test_coupon_validation
    assert_raises(Errors::ValidationError) { Coupon.new(code: "", kind: :flat, value: 10) }
    assert_raises(Errors::ValidationError) { Coupon.new(code: "X", kind: :bogus, value: 10) }
    assert_raises(Errors::ValidationError) { Coupon.new(code: "X", kind: :percent, value: 150) }
    assert_raises(Errors::ValidationError) { Coupon.new(code: "X", kind: :flat, value: 0) }
    assert_raises(Errors::ValidationError) { Coupon.new(code: "X", kind: :flat, value: "abc") }
  end
end
