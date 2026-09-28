class RidesController < ApplicationController
  def create
    ride = container.ride_service.book(
      user_id: params[:user_id], pickup: location_param(:pickup),
      destination: location_param(:destination),
      car_type: params[:car_type], coupon_code: params[:coupon_code]
    )
    render json: ride.to_h, status: :created
  end

  def show
    render json: container.ride_service.find!(params[:id]).to_h
  end

  # `end` is a Ruby keyword, so the action is called `finish` (route: POST /rides/:id/end)
  def finish
    drop = params[:drop].present? ? location_param(:drop) : nil
    render json: container.ride_service.end_ride(params[:id], drop: drop).to_h
  end
end
