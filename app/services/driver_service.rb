class DriverService
  DEFAULT_RATING = 5.0

  def initialize(drivers:)
    @drivers = drivers
  end

  def register(name:, car_type:, location:, rating: nil)
    name = name.to_s.strip
    raise Errors::ValidationError, "name is required" if name.empty?
    raise Errors::ValidationError, "location is required" unless location.is_a?(Location)

    rating = rating.nil? ? DEFAULT_RATING : Float(rating, exception: false)
    raise Errors::ValidationError, "rating must be between 0 and 5" unless rating&.between?(0.0, 5.0)

    @drivers.add(Driver.new(name: name, car_type: CarType.fetch(car_type), location: location, rating: rating))
  end

  def update_location(id, location)
    raise Errors::ValidationError, "location is required" unless location.is_a?(Location)

    driver = @drivers.find!(id)
    driver.location = location
    driver
  end

  def find!(id) = @drivers.find!(id)
end
