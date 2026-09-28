require "bigdecimal"

module Pricing
  # Marginal ("slab") pricing, like income tax: each km is charged at the rate
  # of the slab it falls in, then the total is floored at the minimum fare.
  #
  #   tiers: [[2, 10], [5, 8], [nil, 5]]
  #   => km 0-2 @ 10/km, km 2-5 @ 8/km, everything beyond 5 km @ 5/km
  class FareSchedule
    Tier = Struct.new(:up_to_km, :rate_per_km)

    attr_reader :min_fare, :tiers

    def initialize(min_fare:, tiers:)
      @min_fare = decimal(min_fare)
      @tiers = tiers.map { |up_to, rate| Tier.new(up_to && decimal(up_to), decimal(rate)) }.freeze
      validate!
    end

    def base_fare(distance_km)
      distance = decimal(distance_km)
      raise Errors::ValidationError, "distance must be >= 0" if distance.negative?

      total = BigDecimal("0")
      lower = BigDecimal("0")
      tiers.each do |tier|
        break if distance <= lower

        upper = tier.up_to_km ? [tier.up_to_km, distance].min : distance
        total += (upper - lower) * tier.rate_per_km
        lower = tier.up_to_km || distance
      end

      [total.round(2), min_fare].max
    end

    private

    def decimal(value) = BigDecimal(value.to_s)

    def validate!
      raise ArgumentError, "at least one tier is required" if tiers.empty?
      raise ArgumentError, "last tier must be unbounded (nil)" unless tiers.last.up_to_km.nil?

      bounds = tiers[0..-2].map(&:up_to_km)
      raise ArgumentError, "only the last tier may be unbounded" if bounds.any?(&:nil?)
      raise ArgumentError, "tier bounds must be strictly increasing" unless bounds.each_cons(2).all? { |a, b| a < b }
    end
  end
end
