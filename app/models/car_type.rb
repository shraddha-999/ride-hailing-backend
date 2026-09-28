# Car types and their fare rates live here and only here.
# To add an SUV: add one entry to DEFINITIONS (and, if you want sedans to
# upgrade to it, point `upgrade_to` at it). Nothing else changes.
class CarType
  DEFINITIONS = {
    hatchback: { min_fare: 50, tiers: [[2, 10], [5, 8], [nil, 5]], upgrade_to: :sedan },
    sedan:     { min_fare: 70, tiers: [[2, 14], [5, 11], [nil, 7]] }
  }.freeze

  attr_reader :name, :fare_schedule

  def initialize(name:, min_fare:, tiers:, upgrade_to: nil)
    @name = name
    @fare_schedule = Pricing::FareSchedule.new(min_fare: min_fare, tiers: tiers)
    @upgrade_to = upgrade_to
  end

  REGISTRY = DEFINITIONS.to_h { |name, cfg| [name, new(name: name, **cfg)] }.freeze

  def self.fetch(name)
    REGISTRY.fetch(name.to_s.strip.downcase.to_sym) do
      raise Errors::ValidationError,
            "unknown car type '#{name}' (supported: #{REGISTRY.keys.join(', ')})"
    end
  end

  def self.all = REGISTRY.values

  # This type first, then whatever it may be upgraded to, in order.
  def upgrade_chain
    chain = [self]
    nxt = @upgrade_to
    while nxt
      type = CarType.fetch(nxt)
      raise ArgumentError, "upgrade cycle at #{nxt}" if chain.include?(type)

      chain << type
      nxt = DEFINITIONS.fetch(type.name)[:upgrade_to]
    end
    chain
  end

  def to_s = name.to_s
end
