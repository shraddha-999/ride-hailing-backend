class UsersController < ApplicationController
  def create
    user = container.user_service.register(name: params[:name], phone: params[:phone])
    render json: user.to_h, status: :created
  end

  # GET /users/:id/rides?status=ongoing|completed
  def rides
    rides = container.ride_service.history_for_user(params[:id], status: params[:status])
    render json: rides.map(&:to_h)
  end
end
