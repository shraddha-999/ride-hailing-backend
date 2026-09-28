class ApplicationController < ActionController::API
  # Domain errors carry no HTTP knowledge; we map them by base class here.
  STATUS_BY_ERROR = {
    Errors::ValidationError => :unprocessable_entity, # 422
    Errors::NotFound        => :not_found,            # 404
    Errors::Conflict        => :conflict              # 409
  }.freeze

  rescue_from Errors::DomainError do |e|
    status = STATUS_BY_ERROR.find { |klass, _| e.is_a?(klass) }&.last || :unprocessable_entity
    render json: { error: e.class.name.demodulize.underscore, message: e.message }, status: status
  end

  private

  def container = Container.instance

  def location_param(key)
    raw = params[key]
    raise Errors::ValidationError, "#{key} is required as { lat, lng }" unless raw.respond_to?(:key?)

    Location.new(raw[:lat], raw[:lng])
  end
end
