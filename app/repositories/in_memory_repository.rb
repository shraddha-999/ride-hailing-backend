# Minimal id-keyed store. Swap for ActiveRecord-backed repositories later
# without touching the services (they only use add / find / find! / all).
class InMemoryRepository
  def initialize(name)
    @name = name
    @items = {}
    @next_id = 1
  end

  def add(entity)
    entity.id = @next_id
    @next_id += 1
    @items[entity.id] = entity
  end

  def find(id)
    int = Integer(id.to_s, exception: false)
    int && @items[int]
  end

  def find!(id)
    find(id) || raise(Errors::NotFound, "#{@name} #{id} not found")
  end

  def all = @items.values
end
