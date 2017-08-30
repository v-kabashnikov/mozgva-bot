require './a'

class B
  extend A
  def initialize(command)
    action_object = A.fetch_action_object(command)
  end

end

B.new("cancel")
