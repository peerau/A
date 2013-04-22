# Defines and describes a server.
class Server
  # We can split, that's why we don't have decrease/increase methods
  attr_accessor :usercount
  attr_reader :sid, :name, :desc

  # SID -> server
  @@servers = {}

  def initialize(sid, name, desc)
    @sid = sid
    @name = name
    @desc = desc
    # No idea if we ever need that
    @usercount = 0

    @@servers[@sid] = self
  end

  def obliterate()
    @@servers.delete(@sid)
  end

  def self.find_by_sid(sid)
    return @@servers[sid]
  end

  def self.all()
    return @@servers.values()
  end
end

