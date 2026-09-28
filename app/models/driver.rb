class Driver
  STATUSES = %i[available on_ride].freeze

  attr_accessor :id, :location
  attr_reader :name, :car_type, :rating, :status

  def initialize(name:, car_type:, location:, rating:)
    @name = name
    @car_type = car_type
    @location = location
    @rating = rating
    @status = :available
  end

  def available? = status == :available

  def occupy! = @status = :on_ride

  def release! = @status = :available

  def to_h
    { id: id, name: name, car_type: car_type.to_s, rating: rating,
      status: status, location: location.to_h }
  end
end
