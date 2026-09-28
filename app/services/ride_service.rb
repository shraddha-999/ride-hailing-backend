# Booking, ending and history. All state changes happen under one lock so two
# riders can never be given the same driver (see the concurrency test).
# Trade-off: a single global mutex is simple and correct for one process; with
# a real DB you'd use a row lock / conditional UPDATE on the driver instead.
class RideService
  STATUSES = %w[ongoing completed].freeze

  def initialize(users:, drivers:, rides:, allocator:, pricing:, coupon_service:, clock: -> { Time.now })
    @users = users
    @drivers = drivers
    @rides = rides
    @allocator = allocator
    @pricing = pricing
    @coupon_service = coupon_service
    @clock = clock
    @lock = Mutex.new
  end

  def book(user_id:, pickup:, destination:, car_type:, coupon_code: nil)
    raise Errors::ValidationError, "pickup is required" unless pickup.is_a?(Location)
    raise Errors::ValidationError, "destination is required" unless destination.is_a?(Location)

    @lock.synchronize do
      user = @users.find!(user_id)
      if @rides.all.any? { |r| r.user_id == user.id && r.ongoing? }
        raise Errors::UserBusy, "user #{user.id} already has an ongoing ride"
      end

      requested = CarType.fetch(car_type)
      now = @clock.call
      coupon = coupon_code.to_s.strip.empty? ? nil : @coupon_service.fetch_valid!(coupon_code, now: now)

      driver = @allocator.allocate(car_type: requested, pickup: pickup) ||
               raise(Errors::NoDriverAvailable, "no #{requested} (or upgrade) available near pickup")

      driver.occupy!
      @rides.add(Ride.new(user_id: user.id, driver_id: driver.id,
                          requested_car_type: requested, assigned_car_type: driver.car_type,
                          pickup: pickup, destination: destination, coupon: coupon, started_at: now))
    end
  end

  # Fare distance = straight line from pickup to where the rider was dropped
  # (defaults to the destination given at booking). Priced at the REQUESTED
  # car type, so a free upgrade really is free.
  def end_ride(ride_id, drop: nil)
    raise Errors::ValidationError, "drop must be a location" unless drop.nil? || drop.is_a?(Location)

    @lock.synchronize do
      ride = @rides.find!(ride_id)
      raise Errors::InvalidRideState, "ride #{ride.id} is already completed" unless ride.ongoing?

      drop ||= ride.destination
      distance = ride.pickup.distance_km_to(drop).round(3)
      quote = @pricing.quote(car_type: ride.requested_car_type, distance_km: distance, coupon: ride.coupon)

      driver = @drivers.find!(ride.driver_id)
      driver.location = drop
      driver.release!
      ride.complete!(drop: drop, distance_km: distance, quote: quote, at: @clock.call)
      ride
    end
  end

  def find!(id) = @rides.find!(id)

  def history_for_user(user_id, status: nil)
    user = @users.find!(user_id)
    history { |r| r.user_id == user.id }.then { |rides| filter(rides, status) }
  end

  def history_for_driver(driver_id, status: nil)
    driver = @drivers.find!(driver_id)
    history { |r| r.driver_id == driver.id }.then { |rides| filter(rides, status) }
  end

  private

  def history(&block)
    @rides.all.select(&block).sort_by { |r| [-r.started_at.to_f, -r.id] }
  end

  def filter(rides, status)
    return rides if status.nil? || status.to_s.empty?
    raise Errors::ValidationError, "status must be one of #{STATUSES.join(', ')}" unless STATUSES.include?(status.to_s)

    rides.select { |r| r.status.to_s == status.to_s }
  end
end
