# Channel.rb: Defines an IRC channel class.
require 'A/match.rb'

# Defines an IRC channel.
class Channel
  include Match
  # non-list channel modes we care about:
  # Permanent

  # We only work on InspIRCd and Charybdis --> RFC1459 casemapping ONLY.
  # lowercase name -> object
  @@channels = {}
  attr_reader :name, :ts, :bans, :exempts

  # Converts the given String to lowercase according to RFC1459 rules
  def self.to_lower(s)
    return s.downcase().tr("[]\\", "{}|")
  end

  # Creates a new channel.
  def initialize(name, ts)
    @name = Channel.to_lower(name)
    @ts = ts.to_i()
    # UID array of users in the chan, disregarding CUS
    @users = []

    @permanent = false
    
    # ban and exempt entries are arrays themselves: [nick, ident, host]
    # If a sub-array only has one field, it's an extban on Chary at least
    @bans = []
    @exempts = []

    # We don't care about quiet/invex atm
    # DO NOT initialize modes here, we'll be fed what we need to know by
    # the protocol

    @@channels[@name] = self
  end

  # Input mask, get array
  def parse_ban(mask)
    i_idx = mask.index('!')
    h_idx = mask.index('@')

    extban = false
    if i_idx == nil || h_idx == nil
      # Could be an extban...fsfdsjafknslkfnaskjfnjldf
      if mask[0] == '$'
        extban = true
      else
        raise(ArgumentError, "Invalid ban mask #{mask}.")
      end
    end

    unless extban
      nick = mask[0..(i_idx - 1)]
      ident = mask[(i_idx + 1)..(h_idx - 1)]
      host = mask[(h_idx + 1)..-1]
    end

    return extban ? [mask] : [nick, ident, host]
  end

  # Adds a ban/exempt for the given mask. Type must be either b or e.
  def add_ban(mask, type)
    b = parse_ban(mask)

    if type == 'b'
      @bans.push(b)
    elsif type == 'e'
      @exempts.push(b)
    else
      raise(ArgumentError, "Invalid ban type #{type}, expected b or e.")
    end
  end

  # Removes a ban from this channel
  def del_ban(mask, type)
    b = parse_ban(mask)

    if type == 'b'
      @bans.delete(b)
    elsif type == 'e'
      @exempts.delete(b)
    else
      raise(ArgumentError, "Invalid ban type #{type}, expected b or e.")
    end
  end

  # Adds a user to this channel
  # Arguments:
  # * UID/nick or User object
  def add_user(user)
    if user.is_a?(User)
      @users.push(user)
    else
      @users.push(User.find(user))
    end
  end

  # Removes a user from this channel
  # Arguments:
  # * UID/nick or User object
  def del_user(user)
    if user.is_a?(User)
      @users.delete(user)
    else
      @users.delete(User.find(user))
    end
  end

  # Removes this channel. Does not update the users' state
  def obliterate()
    @users.clear()
    @@channels.delete(Channel.to_lower(@name))
  end

  # Returns the user count
  def get_user_count()
    return @users.length
  end

  # Returns all the users we know are in the channel
  def get_users()
    return @users
  end

  # Sets this channel as permanent/not perm; will not be deleted if 0 users.
  def set_permanent(val)
    @permanent = val
  end

  # Is this channel supposed not to expire?
  def is_permanent?()
    return @permanent
  end

  # Finds a channel by name. If not found, returns nil.
  def self.find_by_name(name)
    return @@channels[Channel.to_lower(name)]
  end

  def self.check_extban(u, extban)
    # XXX: Charybdis-centric
    if extban == '$a' && u.su
      return true
    end

    if extban.start_with?('$a:')
      return true if Match.match(extban[3..-1], u.su, true)
    end

    if extban.start_with?('$c:')
      u.channels.each do |chan|
        return Channel.to_lower(chan.name) == Channel.to_lower(extban[3..-1])
      end
    end

    if extban == '$o'
      return u.isoper
    end

    if extban.start_with?('$r:')
      return true if Match.match(extban[3..-1], u.gecos, true)
    end

    if extban.start_with?('$s:')
      return true if Match.match(extban[3..-1], u.server.name, true)
    end

    if extban.start_with?('$j:')
      # dude fuck your shit
    end

    if extban.start_with?('$x:')
      return true if Match.match(extban[3..-1], "#{u.nick}!#{u.ident}@#{u.host}##{u.gecos}", true)
    end

    if extban == '$z'
      # DUDE SERIOUSLY, THIS ISN'T FUNNY
    end

    return false
  end

  # Finds all channels where a given user is banned from
  def self.find_with_ban_against(u)
    # channel => ban
    @chans = {}
    @@channels.each do |name, c|
      isexempt = false
      c.exempts.each do |e|
        if e.length > 1
          # regular ban
          if Match.match(e[0], u.nick, true) && Match.match(e[1], u.ident, true) &&
            (Match.match(e[2], u.rhost, true) || Match.match(e[2], u.dhost, true) || Match.match(e[2], u.ip, true))
            # Matches, he's exempt
            isexempt = true
            break
          end
        else
          # extban
          isexempt = Channel.check_extban(u, e[0])
        end
      end

      next if isexempt

      c.bans.each do |b|
        if b.length > 1
          # regular ban
          if Match.match(b[0], u.nick, true) && Match.match(b[1], u.ident, true) &&
            (Match.match(b[2], u.rhost, true) || Match.match(b[2], u.dhost, true) || Match.match(b[2], u.ip, true))
            @chans[c] = b
            break
          end
        else
          if Channel.check_extban(u, b[0])
            @chans[c] = b
            break
          end
        end
      end
    end

    return @chans
  end
end

