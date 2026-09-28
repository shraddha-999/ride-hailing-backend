Rails.application.routes.draw do
  post  "users",                 to: "users#create"
  get   "users/:id/rides",       to: "users#rides"

  post  "drivers",               to: "drivers#create"
  patch "drivers/:id/location",  to: "drivers#update_location"
  get   "drivers/:id/rides",     to: "drivers#rides"

  post  "rides",                 to: "rides#create"   # book a ride
  get   "rides/:id",             to: "rides#show"
  post  "rides/:id/end",         to: "rides#finish"   # end a ride, returns the fare

  resources :coupons, only: %i[index create destroy], param: :code
end
