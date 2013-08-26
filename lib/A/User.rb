# User.rb: Defines an IRC user class.

# Defines a user. Usable as Hash key, provided you don't try to do anything
# funny like using newly-created users to look things up. ALWAYS use
# User.find() and friends!
class User
  # UID -> object hash
  @@users_by_uid = {}
  # nick -> object hash, used for commands
  @@users_by_nick = {}

  attr_reader :uid, :rhost, :ip, :channels, :server
  # ident could be changed on Insp IIRC
  # ts can be changed on Chary by nick
  # gecos can be changed on Insp via /setname and /chgname
  attr_accessor :ident, :dhost, :isoper, :isadmin, :olevel, :certfp, :su, :ts, :gecos

  # Matches the lowest common denominator between Charybdis TS6 EUID and
  # InspIRCd UID.
  def initialize(server, uid, nick, ident, dhost, rhost, ip, ts, umodestr, gecos)
    # We only care about this one umode anyway
    @isoper = umodestr.include?('o')
    @isadmin = umodestr.include?('a')
    @olevel = if @isadmin
                "admin"
              elsif @isoper
                "oper"
              else
	              nil
              end
    @uid = uid
    @nick = nick
    @ident = ident
    @dhost = dhost
    @rhost = if rhost == '*' # i.e., no real host
               ip
             else
               rhost
             end
    @ip = ip
    @ts = ts.to_i()
    @gecos = gecos
    @certfp = nil
    @su = nil
    @channels = []
    @server = server

    @@users_by_uid[@uid] = self
    @@users_by_nick[Channel.to_lower(@nick)] = self
  end

  # Updates internal channel list: Adds a user
  # Arguments:
  # * chan name or Channel object
  #
  # Does not propagate the change or update channel!
  def join(channel)
    if channel.is_a?(Channel)
      @channels.push(channel)
    else
      @channels.push(Channel.find(channel))
    end
  end

  # Updates internal channel list: Removes a user
  # Arguments:
  # * chan name or Channel object
  #
  # Does not propagate the change or update channel!
  def part(channel)
    if channel.is_a?(Channel)
      @channels.delete(channel)
    else
      @channels.delete(Channel.find(channel))
    end
  end

  # Obliterates this user and cleans up after it.
  def obliterate()
    @@users_by_uid.delete(@uid)
    @@users_by_nick.delete(Channel.to_lower(@nick))
    part_all()
  end

  # Parts user from all channels. Does not update channel.
  def part_all()
    @channels.clear()
  end

  def info_str()
    return "#{@nick}(#{@uid})!#{@ident}@#{@dhost}(#{@rhost}##{@ip}){#{@server.name}}/#{@gecos}"
  end

  def nick()
    return @nick
  end

  def nick=(nick)
    @@users_by_nick.delete(Channel.to_lower(@nick))
    @nick = nick
    @@users_by_nick[Channel.to_lower(@nick)] = self
  end

  # Returns User object or nil.
  def self.find_by_uid(uid)
    return @@users_by_uid[uid]
  end

  # Returns User object or nil.
  def self.find_by_nick(nick)
    return @@users_by_nick[Channel.to_lower(nick)]
  end

  # Returns User object or nil. Looks up by either UID or nick.
  def self.find(target)
    u = @@users_by_uid[target]
    if u == nil
      return @@users_by_nick[Channel.to_lower(target)]
    else
      return u
    end
  end

  def self.all()
    return @@users_by_uid.values()
  end
end

