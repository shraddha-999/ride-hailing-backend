module Matching
  # Picks the closest driver; ties broken by lowest id so results are deterministic.
  class Nearest
    def select(drivers, pickup)
      drivers.min_by { |d| [d.location.distance_km_to(pickup), d.id] }
    end
  end
end
