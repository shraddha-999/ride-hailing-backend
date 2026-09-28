require "test_helper"

class CouponServiceTest < Minitest::Test
  def setup
    @service = build_container.coupon_service
  end

  def test_add_list_and_delete
    @service.add(code: "save10", kind: "percent", value: 10)
    assert_equal ["SAVE10"], @service.list.map(&:code)
    @service.delete("Save10") # case-insensitive
    assert_empty @service.list
  end

  def test_duplicate_code_is_rejected
    @service.add(code: "A", kind: "flat", value: 5)
    assert_raises(Errors::DuplicateCoupon) { @service.add(code: "a", kind: "flat", value: 5) }
  end

  def test_delete_unknown_code
    assert_raises(Errors::NotFound) { @service.delete("NOPE") }
  end

  def test_fetch_valid_rejects_unknown_and_expired_codes
    @service.add(code: "OLD", kind: "flat", value: 5, expires_at: Time.now - 60)
    assert_raises(Errors::InvalidCoupon) { @service.fetch_valid!("NOPE") }
    assert_raises(Errors::InvalidCoupon) { @service.fetch_valid!("OLD") }
  end
end
