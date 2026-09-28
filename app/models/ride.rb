class Ride
  attr_accessor :id
  attr_reader :user_id, :driver_id, :requested_car_type, :assigned_car_type,
              :pickup, :destination, :coupon, :started_at,
              :status, :drop, :distance_km, :quote, :ended_at

  def initialize(user_id:, driver_id:, requested_car_type:, assigned_car_type:,
                 pickup:, destination:, coupon:, started_at:)
    @user_id = user_id
    @driver_id = driver_id
    @requested_car_type = requested_car_type
    @assigned_car_type = assigned_car_type
    @pickup = pickup
    @destination = destination
    @coupon = coupon # snapshot taken at booking: deleting the coupon later doesn't change this ride
    @started_at = started_at
    @status = :ongoing
  end

  def ongoing? = status == :ongoing

  def completed? = status == :completed

  # Rider asked for one type but a better one turned up. Priced at the requested type.
  def upgraded? = requested_car_type != assigned_car_type

  def complete!(drop:, distance_km:, quote:, at:)
    @drop = drop
    @distance_km = distance_km
    @quote = quote
    @ended_at = at
    @status = :completed
  end

  def to_h
    {
      id: id, status: status, user_id: user_id, driver_id: driver_id,
      requested_car_type: requested_car_type.to_s, assigned_car_type: assigned_car_type.to_s,
      upgraded: upgraded?, pickup: pickup.to_h, destination: destination.to_h,
      coupon_code: coupon&.code, started_at: started_at.iso8601,
      ended_at: ended_at&.iso8601, distance_km: distance_km, fare: quote&.to_h
    }
  end
end
