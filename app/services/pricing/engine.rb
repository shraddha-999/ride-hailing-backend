require "bigdecimal"

module Pricing
  # Single place that turns (car type, distance, coupon) into a Quote.
  # Order of operations: tiered fare -> minimum fare -> coupon. So a coupon can
  # take a ride below the minimum fare (it can never go below zero).
  #
  # Surge pricing would slot in here as one more step (a multiplier applied to
  # the base fare before the coupon); it is intentionally not built yet.
  class Engine
    def quote(car_type:, distance_km:, coupon: nil)
      base = car_type.fare_schedule.base_fare(distance_km)
      discount = coupon ? coupon.discount_for(base) : BigDecimal("0")
      Quote.new(base_fare: base, discount: discount, coupon_code: coupon&.code)
    end
  end
end
