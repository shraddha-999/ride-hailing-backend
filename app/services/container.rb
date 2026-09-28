# Composition root: the only place that knows which concrete classes are wired
# together. Controllers, tests and the demo script all build services from here.
class Container
  DEFAULT_RADIUS_KM = 5.0

  class << self
    def instance = @instance ||= new

    def reset! = @instance = nil
  end

  attr_reader :user_service, :driver_service, :coupon_service, :ride_service

  def initialize(radius_km: Float(ENV.fetch("SEARCH_RADIUS_KM", DEFAULT_RADIUS_KM)),
                 matching: ENV.fetch("MATCHING_STRATEGY", "nearest"),
                 clock: -> { Time.now })
    users = InMemoryRepository.new("user")
    drivers = InMemoryRepository.new("driver")
    rides = InMemoryRepository.new("ride")
    coupons = CouponRepository.new

    @user_service = UserService.new(users: users)
    @driver_service = DriverService.new(drivers: drivers)
    @coupon_service = CouponService.new(coupons: coupons)

    allocator = DriverAllocator.new(drivers: drivers, radius_km: radius_km,
                                    strategy: Matching::Registry.build(matching))
    @ride_service = RideService.new(users: users, drivers: drivers, rides: rides,
                                    allocator: allocator, pricing: Pricing::Engine.new,
                                    coupon_service: @coupon_service, clock: clock)
  end
end
