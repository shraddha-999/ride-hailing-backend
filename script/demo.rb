#!/usr/bin/env ruby
# Walks through the edge cases the reviewers ask to see. Plain Ruby, no server.
#   ruby script/demo.rb
require_relative "../lib/domain_loader"
DomainLoader.load!

KM = Location::EARTH_RADIUS_KM * Math::PI / 180
BASE = Location.new(12.9716, 77.5946)
def north(km) = Location.new(BASE.lat + km / KM, BASE.lng)

def step(title) = puts("\n== #{title}")
def attempt
  yield
rescue Errors::DomainError => e
  puts "   rejected -> #{e.class.name}: #{e.message}"
end

app = Container.new(radius_km: 5.0, matching: "nearest")
users = app.user_service
drivers = app.driver_service
rides = app.ride_service

asha = users.register(name: "Asha", phone: "9000000001")
ben  = users.register(name: "Ben",  phone: "9000000002")

step "1. No driver in radius"
drivers.register(name: "Far Hatch", car_type: :hatchback, location: north(8), rating: 4.8)
attempt { rides.book(user_id: asha.id, pickup: BASE, destination: north(10), car_type: :hatchback) }

step "2. Minimum fare (1 km ride)"
near_hatch = drivers.register(name: "Near Hatch", car_type: :hatchback, location: north(1), rating: 4.2)
ride = rides.book(user_id: asha.id, pickup: BASE, destination: north(1), car_type: :hatchback)
puts "   fare: #{rides.end_ride(ride.id).quote.to_h}"

step "3. Hatchback -> Sedan free upgrade (only a sedan is nearby)"
drivers.update_location(near_hatch.id, north(40)) # take the hatchback out of range
sedan = drivers.register(name: "Sedan Sam", car_type: :sedan, location: north(2), rating: 4.9)
ride = rides.book(user_id: asha.id, pickup: BASE, destination: north(10), car_type: :hatchback)
puts "   requested=#{ride.requested_car_type} assigned=#{ride.assigned_car_type} upgraded=#{ride.upgraded?}"
puts "   fare at HATCHBACK rate: #{rides.end_ride(ride.id).quote.to_h}"

step "4. Coupons: valid, invalid, deleted"
app.coupon_service.add(code: "SAVE10", kind: "percent", value: 10)
app.coupon_service.add(code: "FLAT20", kind: "flat", value: 20)
drivers.update_location(sedan.id, north(1))
ride = rides.book(user_id: asha.id, pickup: BASE, destination: north(10), car_type: :sedan, coupon_code: "save10")
puts "   SAVE10 on a 10 km sedan ride: #{rides.end_ride(ride.id).quote.to_h}"
attempt { rides.book(user_id: asha.id, pickup: BASE, destination: north(10), car_type: :sedan, coupon_code: "BOGUS") }
app.coupon_service.delete("FLAT20")
attempt { app.coupon_service.delete("FLAT20") }

step "5. Ride history"
puts "   Asha: " + rides.history_for_user(asha.id).map { |r| "##{r.id}(#{r.status})" }.join(", ")
puts "   Sedan Sam: " + rides.history_for_driver(sedan.id).map { |r| "##{r.id}(#{r.status})" }.join(", ")

step "6. Same driver, two riders"
drivers.update_location(sedan.id, north(1))
ride = rides.book(user_id: asha.id, pickup: BASE, destination: north(3), car_type: :sedan)
attempt { rides.book(user_id: ben.id, pickup: BASE, destination: north(3), car_type: :sedan) }
