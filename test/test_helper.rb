require "minitest/autorun"
require "bigdecimal"
require_relative "../lib/domain_loader"

DomainLoader.load!

module TestHelpers
  KM_PER_DEGREE_LAT = Location::EARTH_RADIUS_KM * Math::PI / 180
  BASE = Location.new(12.9716, 77.5946)

  # A point exactly `km` due north of BASE, so distances in tests are exact.
  def north(km) = Location.new(BASE.lat + km / KM_PER_DEGREE_LAT, BASE.lng)

  def bd(value) = BigDecimal(value.to_s)

  # Fresh, isolated wiring per test.
  def build_container(**opts) = Container.new(radius_km: 5.0, matching: "nearest", **opts)
end

class Minitest::Test
  include TestHelpers
end
