# Immutable lat/lng value object. Distance is straight-line (haversine).
class Location
  EARTH_RADIUS_KM = 6371.0088

  attr_reader :lat, :lng

  def initialize(lat, lng)
    @lat = to_float(lat, "lat")
    @lng = to_float(lng, "lng")
    raise Errors::ValidationError, "lat must be between -90 and 90" unless (-90.0..90.0).cover?(@lat)
    raise Errors::ValidationError, "lng must be between -180 and 180" unless (-180.0..180.0).cover?(@lng)
    freeze
  end

  def distance_km_to(other)
    rad = Math::PI / 180
    dlat = (other.lat - lat) * rad
    dlng = (other.lng - lng) * rad
    a = Math.sin(dlat / 2)**2 +
        Math.cos(lat * rad) * Math.cos(other.lat * rad) * Math.sin(dlng / 2)**2
    2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(a))
  end

  def ==(other)
    other.is_a?(Location) && lat == other.lat && lng == other.lng
  end
  alias eql? ==

  def hash = [lat, lng].hash

  def to_h = { lat: lat, lng: lng }

  private

  def to_float(value, field)
    Float(value)
  rescue ArgumentError, TypeError
    raise Errors::ValidationError, "#{field} must be a number"
  end
end
