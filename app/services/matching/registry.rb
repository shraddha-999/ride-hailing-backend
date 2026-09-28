module Matching
  # Strategy is chosen by name (MATCHING_STRATEGY env var), so switching it
  # never touches booking logic. A new strategy = new class + one line here.
  class Registry
    STRATEGIES = {
      "nearest" => Nearest,
      "highest_rated" => HighestRated
    }.freeze

    def self.build(name)
      STRATEGIES.fetch(name.to_s) do
        raise Errors::ValidationError,
              "unknown matching strategy '#{name}' (supported: #{STRATEGIES.keys.join(', ')})"
      end.new
    end
  end
end
