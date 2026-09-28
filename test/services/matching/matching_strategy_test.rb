require "test_helper"

class MatchingStrategyTest < Minitest::Test
  def setup_with(strategy)
    @c = Container.new(radius_km: 5.0, matching: strategy)
    @user = @c.user_service.register(name: "Asha", phone: "9000000001")
    @near = @c.driver_service.register(name: "Near", car_type: :hatchback, location: north(0.5), rating: 4.0)
    @top  = @c.driver_service.register(name: "Top",  car_type: :hatchback, location: north(3), rating: 4.9)
  end

  def booked_driver_id
    @c.ride_service.book(user_id: @user.id, pickup: BASE, destination: north(5), car_type: :hatchback).driver_id
  end

  def test_nearest_strategy
    setup_with("nearest")
    assert_equal @near.id, booked_driver_id
  end

  def test_highest_rated_strategy
    setup_with("highest_rated")
    assert_equal @top.id, booked_driver_id
  end

  def test_unknown_strategy_is_rejected
    assert_raises(Errors::ValidationError) { Container.new(matching: "random") }
  end
end
