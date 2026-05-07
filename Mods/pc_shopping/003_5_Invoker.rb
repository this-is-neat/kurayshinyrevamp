class Invoker
  @@msg_queue = Queue.new
  @@msg_types = Hash.new

  # runs messages from the msg queue pool on the main thread (constantly ran by an event).
  def self.handle
    until @@msg_queue.empty?
      msg = @@msg_queue.pop

      unless @@msg_types.key?(msg[0])
        raise "Unkown message type given to invoker. #{msg[0]}"
      end
      if @@msg_types[msg[0]].nil?
        raise "Tried to call a null method."
      end

      func_name = @@msg_types[msg[0]]
      send(func_name, msg[1])
    end
  end

  def self.add_type(type_name, function)
    unless @@msg_types.key?(type_name)
      @@msg_types[type_name] = function
    end
  end

  def self.populate(type_name, message)
    # return nil if @@msg_types.key?(type_name)
    @@msg_queue << [type_name, message]
  end

  def self.msg_queue
    @@msg_queue
  end
  def self.msg_types
    @@msg_types
  end

end

# Warning: calling from a thread manually may lead to a crash.
def msgBox(pbMsg)
  msgwindow = pbCreateMessageWindow(nil, nil)
  pbMessageDisplay(msgwindow, pbMsg)
  pbDisposeMessageWindow(msgwindow)
  Input.update
end

Invoker.add_type('msgBox', :msgBox)