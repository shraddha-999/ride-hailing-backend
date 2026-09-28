# Ride Hailing Backend (Rails API, in-memory)

Rails API-only app. The domain (pricing, matching, booking) is plain Ruby under
`app/models`, `app/services`, `app/repositories`; controllers are thin. Storage is
in-memory, so state resets when the server restarts.

## Run

```bash
bundle install
bin/rails server            # http://localhost:3000
bin/test                    # 49 tests, plain Ruby, no server needed
ruby script/demo.rb         # walks through the edge cases
```

Config (env vars): `SEARCH_RADIUS_KM` (default 5), `MATCHING_STRATEGY` (`nearest` | `highest_rated`).

## API

| Action | Request |
|---|---|
| Register user | `POST /users` `{name, phone}` |
| Register driver | `POST /drivers` `{name, car_type, location:{lat,lng}, rating?}` |
| Update cab location | `PATCH /drivers/:id/location` `{location:{lat,lng}}` |
| Book ride | `POST /rides` `{user_id, pickup:{lat,lng}, destination:{lat,lng}, car_type, coupon_code?}` |
| End ride + fare | `POST /rides/:id/end` `{drop?:{lat,lng}}` |
| User / driver history | `GET /users/:id/rides`, `GET /drivers/:id/rides` (`?status=ongoing\|completed`) |
| Coupons | `GET /coupons`, `POST /coupons` `{code, kind: percent\|flat, value, max_discount?, expires_at?}`, `DELETE /coupons/:code` |

Errors: 422 validation / invalid coupon, 404 not found, 409 conflict (no driver, user already on a ride, ride already ended, duplicate).

## Assumptions (where the spec was silent)

- **Distance** is straight-line (haversine) from pickup to the drop point. `end` uses the destination given at booking unless a `drop` is passed.
- **Tiers are marginal**, like tax slabs: 0-2 km @ ₹10, 2-5 km @ ₹8, beyond 5 km @ ₹5. The spec's "3-5 km" leaves a gap between 2 and 3, so I read it as continuous slabs with fractional km.
- **Minimum fare is applied before the coupon**, so a coupon can push a ride below the minimum (never below ₹0).
- **Hatchback rates:** min ₹50, 10/8/5. **Sedan rates:** min ₹70, 14/11/7 (my numbers; the spec gives only the hatchback-style example).
- **Free upgrade:** a hatchback request tries hatchbacks first, then sedans. The ride is **priced at the requested type**. Sedan requests are never downgraded.
- **Coupons:** `percent` (with optional cap) and `flat`. Codes are case-insensitive. An unknown or expired code **rejects the booking** rather than being ignored. The coupon is snapshotted at booking, so deleting it mid-ride doesn't change that ride. No per-user usage limits.
- A user can have **one ongoing ride** at a time. Search radius is 5 km, inclusive. New drivers default to rating 5.0.
- When a ride ends, the driver becomes available again **at the drop location**.

## Design decisions and trade-offs

- **One place per change.** A new car type or fare is one entry in `CarType::DEFINITIONS`. A new matching strategy is a class plus one line in `Matching::Registry`. Pricing rules live in `Pricing::Engine` / `FareSchedule`.
- **Matching is separate from booking.** `DriverAllocator` decides who is eligible (available, in radius, right type, upgrade chain); the strategy only picks among candidates. Switching strategy never touches `RideService`.
- **Concurrency:** booking and ending run under one mutex, so two riders can't get the same driver (tested with 20 racing threads). Simple and correct for one process; with a real DB I'd use a row lock or conditional update on the driver.
- **Money is `BigDecimal`**, rounded to 2 places; never floats.
- **No ActiveRecord.** The spec allows in-memory storage; repositories expose a tiny interface so a DB can replace them.
- **Reloading is off** in `config/environments/*` because in-memory state lives in `Container.instance`.

## Not built / with more time

- Surge pricing (would be one more step in `Pricing::Engine`), cancellation with a fee policy.
- Real route distance instead of straight-line; fare from actual driver location updates.
- Persistence, auth, per-user coupon limits, HTTP-level request tests.

## How I used AI

_Fill this in honestly before submitting: what you prompted for, what you rejected or rewrote, and why._
