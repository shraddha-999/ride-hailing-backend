# Loads app/models, app/services and app/repositories WITHOUT booting Rails,
# so tests and the demo script run as plain Ruby. Uses Zeitwerk (the same
# loader Rails uses) when the gem is installed, so file/constant naming is
# checked the same way; otherwise falls back to a retry-until-it-loads loop.
require "time"
require "bigdecimal"

module DomainLoader
  ROOT = File.expand_path("..", __dir__)
  # services first: CarType builds Pricing::FareSchedule at load time
  DIRS = %w[app/services app/repositories app/models].map { |d| File.join(ROOT, d) }

  def self.load!
    return if defined?(Rails) && Rails.respond_to?(:application) && Rails.application # Rails autoloads already

    begin
      require "zeitwerk"
      loader = Zeitwerk::Loader.new
      DIRS.each { |d| loader.push_dir(d) }
      loader.setup
      loader.eager_load
    rescue LoadError
      fallback_load
    end
  end

  def self.fallback_load
    pending = DIRS.flat_map { |d| Dir[File.join(d, "**/*.rb")].sort } # sort per dir, keeping DIRS order
    pending.size.times do
      pending = pending.reject do |f|
        require f
        true
      rescue NameError
        false
      end
      break if pending.empty?
    end
    raise "could not load: #{pending.join(', ')}" unless pending.empty?
  end
end
