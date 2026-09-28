# Coupons are keyed by (case-insensitive) code, not by generated id.
class CouponRepository
  def initialize
    @items = {}
  end

  def add(coupon)
    raise Errors::DuplicateCoupon, "coupon #{coupon.code} already exists" if @items.key?(coupon.code)

    @items[coupon.code] = coupon
  end

  def find(code) = @items[normalize(code)]

  def delete(code)
    @items.delete(normalize(code)) || raise(Errors::NotFound, "coupon #{code} not found")
  end

  def all = @items.values

  private

  def normalize(code) = code.to_s.strip.upcase
end
