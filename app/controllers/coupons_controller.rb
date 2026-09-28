class CouponsController < ApplicationController
  def index
    render json: container.coupon_service.list.map(&:to_h)
  end

  def create
    coupon = container.coupon_service.add(
      code: params[:code], kind: params[:kind], value: params[:value],
      max_discount: params[:max_discount], expires_at: parse_time(params[:expires_at])
    )
    render json: coupon.to_h, status: :created
  end

  def destroy
    render json: container.coupon_service.delete(params[:code]).to_h
  end

  private

  def parse_time(value)
    return nil if value.blank?

    Time.iso8601(value.to_s)
  rescue ArgumentError
    raise Errors::ValidationError, "expires_at must be an ISO 8601 timestamp"
  end
end
