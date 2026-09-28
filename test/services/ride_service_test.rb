require "test_helper"

class RideServiceTest < Minitest::Test
  def setup
    @c = build_container
    @rides = @c.ride_service
    @user = @c.user_service.register(name: "Asha", phone: "9000000001")
  end

  def add_driver(car_type: :hatchback, km_away: 1, rating: 4.5, name: "Driver")
    @c.driver_service.register(name: name, car_type: car_type, location: north(km_away), rating: rating)
  end

  def book(user: @user, car_type: :hatchback, coupon_code: nil, destination_km: 10)
    @rides.book(user_id: user.id, pickup: BASE, destination: north(destination_km),
                car_type: car_type, coupon_code: coupon_code)
  end

  # ---- booking ----

  def test_books_nearby_driver_and_marks_them_busy
    driver = add_driver
    ride = book
    assert_equal driver.id, ride.driver_id
    assert ride.ongoing?
    refute driver.available?
  end

  def test_no_driver_at_all
    assert_raises(Errors::NoDriverAvailable) { book }
  end

  def test_driver_outside_radius_is_ignored
    add_driver(km_away: 5.5)
    assert_raises(Errors::NoDriverAvailable) { book }
  end

  def test_driver_exactly_at_radius_is_included
    add_driver(km_away: 4.999)
    assert book
  end

  def test_busy_driver_is_not_offered_to_someone_else
    add_driver
    book
    other = @c.user_service.register(name: "Ben", phone: "9000000002")
    assert_raises(Errors::NoDriverAvailable) { book(user: other) }
  end

  def test_user_cannot_have_two_ongoing_rides
    add_driver
    add_driver(name: "Second")
    book
    assert_raises(Errors::UserBusy) { book }
  end

  def test_unknown_user_and_car_type
    assert_raises(Errors::NotFound) { @rides.book(user_id: 99, pickup: BASE, destination: north(1), car_type: :hatchback) }
    assert_raises(Errors::ValidationError) { book(car_type: :spaceship) }
  end

  # ---- car types & free upgrade ----

  def test_hatchback_request_prefers_a_hatchback_even_if_a_sedan_is_closer
    hatch = add_driver(car_type: :hatchback, km_away: 3)
    add_driver(car_type: :sedan, km_away: 0.5)
    ride = book
    assert_equal hatch.id, ride.driver_id
    refute ride.upgraded?
  end

  def test_hatchback_is_upgraded_to_sedan_at_hatchback_price
    sedan = add_driver(car_type: :sedan)
    ride = book(car_type: :hatchback)
    assert_equal sedan.id, ride.driver_id
    assert ride.upgraded?
    assert_equal "sedan", ride.assigned_car_type.to_s

    done = @rides.end_ride(ride.id)
    assert_equal bd(69), done.quote.total # hatchback rate for 10 km, NOT the sedan's 96
  end

  def test_sedan_request_is_never_downgraded_to_hatchback
    add_driver(car_type: :hatchback)
    assert_raises(Errors::NoDriverAvailable) { book(car_type: :sedan) }
  end

  # ---- ending a ride ----

  def test_end_ride_returns_fare_frees_driver_and_moves_them_to_drop
    driver = add_driver
    ride = book(destination_km: 10)
    done = @rides.end_ride(ride.id)

    assert done.completed?
    assert_in_delta 10.0, done.distance_km, 0.001
    assert_equal bd(69), done.quote.total
    assert driver.available?
    assert_equal ride.destination, driver.location
  end

  def test_end_ride_with_custom_drop_uses_actual_distance
    add_driver
    ride = book(destination_km: 10)
    done = @rides.end_ride(ride.id, drop: north(3))
    assert_in_delta 3.0, done.distance_km, 0.001
    assert_equal bd(50), done.quote.total # 3 km = 20 + 8 = 28 -> minimum fare 50
  end

  def test_short_ride_pays_minimum_fare
    add_driver
    ride = book(destination_km: 1)
    assert_equal bd(50), @rides.end_ride(ride.id).quote.total
  end

  def test_cannot_end_a_ride_twice
    add_driver
    ride = book
    @rides.end_ride(ride.id)
    assert_raises(Errors::InvalidRideState) { @rides.end_ride(ride.id) }
  end

  def test_driver_can_be_rebooked_after_ride_ends
    add_driver
    ride = book(destination_km: 1) # driver ends the ride 1 km from the next pickup
    @rides.end_ride(ride.id)
    assert book
  end

  # ---- coupons ----

  def test_coupon_is_applied_to_the_final_fare
    add_driver
    @c.coupon_service.add(code: "SAVE10", kind: "percent", value: 10)
    ride = book(coupon_code: "save10")
    assert_equal bd("62.1"), @rides.end_ride(ride.id).quote.total
  end

  def test_invalid_coupon_rejects_the_booking_and_keeps_the_driver_free
    driver = add_driver
    assert_raises(Errors::InvalidCoupon) { book(coupon_code: "BOGUS") }
    assert driver.available?
  end

  def test_expired_coupon_is_rejected
    add_driver
    @c.coupon_service.add(code: "OLD", kind: "flat", value: 10, expires_at: Time.now - 1)
    assert_raises(Errors::InvalidCoupon) { book(coupon_code: "OLD") }
  end

  def test_coupon_deleted_mid_ride_is_still_honoured
    add_driver
    @c.coupon_service.add(code: "FLAT20", kind: "flat", value: 20)
    ride = book(coupon_code: "FLAT20")
    @c.coupon_service.delete("FLAT20")
    assert_equal bd(49), @rides.end_ride(ride.id).quote.total
  end

  # ---- history ----

  def test_user_and_driver_history_show_ongoing_and_completed
    driver = add_driver
    first = book(destination_km: 1)
    @rides.end_ride(first.id)
    second = book

    all = @rides.history_for_user(@user.id)
    assert_equal [second.id, first.id], all.map(&:id) # newest first
    assert_equal [second.id], @rides.history_for_user(@user.id, status: "ongoing").map(&:id)
    assert_equal [first.id], @rides.history_for_driver(driver.id, status: "completed").map(&:id)
    assert_raises(Errors::ValidationError) { @rides.history_for_user(@user.id, status: "bogus") }
  end

  def test_history_only_contains_own_rides
    add_driver
    other = @c.user_service.register(name: "Ben", phone: "9000000002")
    book
    assert_empty @rides.history_for_user(other.id)
  end

  # ---- driver location ----

  def test_updating_a_drivers_location_changes_who_is_in_range
    driver = add_driver(km_away: 20)
    assert_raises(Errors::NoDriverAvailable) { book }
    @c.driver_service.update_location(driver.id, north(1))
    assert book
  end

  # ---- concurrency ----

  def test_two_riders_racing_for_one_driver_only_one_wins
    add_driver
    riders = Array.new(20) { |i| @c.user_service.register(name: "R#{i}", phone: "800000#{i.to_s.rjust(4, '0')}") }
    results = Queue.new
    gate = Queue.new

    threads = riders.map do |rider|
      Thread.new do
        gate.pop # all threads released together
        begin
          book(user: rider)
          results << :booked
        rescue Errors::NoDriverAvailable
          results << :rejected
        end
      end
    end
    riders.size.times { gate << :go }
    threads.each(&:join)

    outcomes = Array.new(results.size) { results.pop }
    assert_equal 1, outcomes.count(:booked)
    assert_equal 19, outcomes.count(:rejected)
  end
end
