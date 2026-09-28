module Pricing
  # Breakdown of a fare: what the distance costs, what the coupon took off, what to pay.
  class Quote
    attr_reader :base_fare, :discount, :total, :coupon_code

    def initialize(base_fare:, discount:, coupon_code: nil)
      @base_fare = base_fare
      @discount = discount
      @total = base_fare - discount
      @coupon_code = coupon_code
    end

    def to_h
      { base_fare: base_fare.to_f, discount: discount.to_f, total: total.to_f, coupon_code: coupon_code }
    end
  end
end
