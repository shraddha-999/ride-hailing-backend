module Matching
  # Best rating wins; ties go to the nearer driver, then lowest id.
  class HighestRated
    def select(drivers, pickup)
      drivers.min_by { |d| [-d.rating, d.location.distance_km_to(pickup), d.id] }
    end
  end
end
