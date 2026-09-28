# One small hierarchy so the HTTP layer can map errors by base class
# (Validation -> 422, NotFound -> 404, Conflict -> 409) without the domain
# knowing anything about HTTP.
module Errors
  class DomainError < StandardError; end

  class ValidationError < DomainError; end
  class InvalidCoupon < ValidationError; end

  class NotFound < DomainError; end

  class Conflict < DomainError; end
  class NoDriverAvailable < Conflict; end
  class UserBusy < Conflict; end
  class InvalidRideState < Conflict; end
  class DuplicateCoupon < Conflict; end
  class DuplicateUser < Conflict; end
end
