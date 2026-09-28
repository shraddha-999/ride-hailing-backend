class DriversController < ApplicationController
  def create
    driver = container.driver_service.register(
      name: params[:name], car_type: params[:car_type],
      location: location_param(:location), rating: params[:rating]
    )
    render json: driver.to_h, status: :created
  end

  def update_location
    driver = container.driver_service.update_location(params[:id], location_param(:location))
    render json: driver.to_h
  end

  # GET /drivers/:id/rides?status=ongoing|completed
  def rides
    rides = container.ride_service.history_for_driver(params[:id], status: params[:status])
    render json: rides.map(&:to_h)
  end
end
