require "test_helper"

class FareScheduleTest < Minitest::Test
  # min_fare 0 exposes the raw tier maths; the hatchback schedule adds the 50 floor.
  def raw = Pricing::FareSchedule.new(min_fare: 0, tiers: [[2, 10], [5, 8], [nil, 5]])

  def hatchback = CarType.fetch(:hatchback).fare_schedule

  def sedan = CarType.fetch(:sedan).fare_schedule

  def test_each_tier_is_charged_marginally
    assert_equal bd(10),   raw.base_fare(1)     # 1 * 10
    assert_equal bd(20),   raw.base_fare(2)     # 2 * 10
    assert_equal bd(32),   raw.base_fare(3.5)   # 20 + 1.5 * 8
    assert_equal bd(44),   raw.base_fare(5)     # 20 + 3 * 8
    assert_equal bd(49),   raw.base_fare(6)     # 20 + 24 + 1 * 5
    assert_equal bd(69),   raw.base_fare(10)    # 20 + 24 + 5 * 5
    assert_equal bd(119),  raw.base_fare(20)    # 20 + 24 + 15 * 5
  end

  def test_zero_distance_costs_nothing_before_minimum
    assert_equal bd(0), raw.base_fare(0)
  end

  def test_minimum_fare_applies_to_short_rides
    assert_equal bd(50), hatchback.base_fare(0)
    assert_equal bd(50), hatchback.base_fare(0.5)  # 5 -> floored to 50
    assert_equal bd(50), hatchback.base_fare(2)    # 20 -> floored to 50
    assert_equal bd(50), hatchback.base_fare(6)    # 49 -> floored to 50
  end

  def test_minimum_fare_stops_applying_once_tiers_exceed_it
    assert_equal bd(54), hatchback.base_fare(7)    # 20 + 24 + 2 * 5
    assert_equal bd(69), hatchback.base_fare(10)
  end

  def test_car_types_have_different_rates
    assert_equal bd(69), hatchback.base_fare(10)
    assert_equal bd(96), sedan.base_fare(10)       # 28 + 33 + 35
    assert_equal bd(70), sedan.base_fare(1)        # sedan minimum is 70
  end

  def test_negative_distance_is_rejected
    assert_raises(Errors::ValidationError) { raw.base_fare(-1) }
  end

  def test_invalid_tier_configuration_is_rejected
    assert_raises(ArgumentError) { Pricing::FareSchedule.new(min_fare: 0, tiers: []) }
    assert_raises(ArgumentError) { Pricing::FareSchedule.new(min_fare: 0, tiers: [[2, 10]]) }
    assert_raises(ArgumentError) { Pricing::FareSchedule.new(min_fare: 0, tiers: [[5, 10], [2, 8], [nil, 5]]) }
  end
end
