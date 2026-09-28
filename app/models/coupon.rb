require "bigdecimal"

class Coupon
  KINDS = %i[percent flat].freeze

  attr_reader :code, :kind, :value, :max_discount, :expires_at

  # kind :percent -> value is 1..100, optional max_discount cap (in rupees)
  # kind :flat    -> value is a rupee amount off
  def initialize(code:, kind:, value:, max_discount: nil, expires_at: nil)
    @code = code.to_s.strip.upcase
    raise Errors::ValidationError, "coupon code is required" if @code.empty?

    @kind = kind.to_s.strip.downcase.to_sym
    raise Errors::ValidationError, "kind must be one of #{KINDS.join(', ')}" unless KINDS.include?(@kind)

    @value = decimal(value, "value")
    raise Errors::ValidationError, "value must be > 0" unless @value.positive?
    raise Errors::ValidationError, "percent must be <= 100" if percent? && @value > 100

    @max_discount = max_discount.nil? ? nil : decimal(max_discount, "max_discount")
    raise Errors::ValidationError, "max_discount must be > 0" if @max_discount && !@max_discount.positive?

    @expires_at = expires_at
  end

  def percent? = kind == :percent

  def expired?(now = Time.now)
    !expires_at.nil? && now > expires_at
  end

  # Never discounts more than the fare itself, and never more than the cap.
  def discount_for(fare)
    raw = percent? ? fare * value / 100 : value
    raw = [raw, max_discount].min if max_discount
    [raw.round(2), fare].min
  end

  def to_h
    { code: code, kind: kind, value: value.to_f, max_discount: max_discount&.to_f,
      expires_at: expires_at&.iso8601 }
  end

  private

  def decimal(v, field)
    BigDecimal(v.to_s)
  rescue ArgumentError, TypeError
    raise Errors::ValidationError, "#{field} must be a number"
  end
end
