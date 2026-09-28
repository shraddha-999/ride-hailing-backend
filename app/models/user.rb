class User
  attr_accessor :id
  attr_reader :name, :phone

  def initialize(name:, phone:)
    @name = name
    @phone = phone
  end

  def to_h = { id: id, name: name, phone: phone }
end
