require "test_helper"

class LocationTest < Minitest::Test
  def test_distance_is_symmetric_and_zero_for_same_point
    assert_in_delta 0.0, BASE.distance_km_to(BASE), 1e-9
    assert_in_delta BASE.distance_km_to(north(7)), north(7).distance_km_to(BASE), 1e-9
    assert_in_delta 7.0, BASE.distance_km_to(north(7)), 1e-6
  end

  def test_rejects_bad_coordinates
    assert_raises(Errors::ValidationError) { Location.new(91, 0) }
    assert_raises(Errors::ValidationError) { Location.new(0, 181) }
    assert_raises(Errors::ValidationError) { Location.new("abc", 0) }
    assert_raises(Errors::ValidationError) { Location.new(nil, 0) }
  end
end
