class UserService
  def initialize(users:)
    @users = users
  end

  def register(name:, phone:)
    name = name.to_s.strip
    phone = phone.to_s.strip
    raise Errors::ValidationError, "name is required" if name.empty?
    raise Errors::ValidationError, "phone is required" if phone.empty?
    raise Errors::DuplicateUser, "phone #{phone} is already registered" if @users.all.any? { |u| u.phone == phone }

    @users.add(User.new(name: name, phone: phone))
  end

  def find!(id) = @users.find!(id)
end
