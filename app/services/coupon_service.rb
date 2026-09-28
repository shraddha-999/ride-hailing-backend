class CouponService
  def initialize(coupons:)
    @coupons = coupons
  end

  def add(code:, kind:, value:, max_discount: nil, expires_at: nil)
    @coupons.add(Coupon.new(code: code, kind: kind, value: value,
                            max_discount: max_discount, expires_at: expires_at))
  end

  def delete(code) = @coupons.delete(code)

  def list = @coupons.all

  # Used at booking time: an unknown or expired code is rejected up front
  # rather than silently ignored, so the rider is never surprised at the end.
  def fetch_valid!(code, now: Time.now)
    coupon = @coupons.find(code) || raise(Errors::InvalidCoupon, "coupon #{code} does not exist")
    raise Errors::InvalidCoupon, "coupon #{coupon.code} has expired" if coupon.expired?(now)

    coupon
  end
end
