# Finds a driver for a request: available, within radius, of the requested car
# type; if none, tries each type in its upgrade chain (hatchback -> sedan).
# WHICH candidate wins is delegated to the matching strategy.
class DriverAllocator
  def initialize(drivers:, radius_km:, strategy:)
    @drivers = drivers
    @radius_km = radius_km
    @strategy = strategy
  end

  def allocate(car_type:, pickup:)
    car_type.upgrade_chain.each do |type|
      candidates = @drivers.all.select do |d|
        d.available? && d.car_type == type && d.location.distance_km_to(pickup) <= @radius_km
      end
      return @strategy.select(candidates, pickup) unless candidates.empty?
    end
    nil
  end
end
