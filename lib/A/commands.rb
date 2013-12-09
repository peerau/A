# commands.rb: Command and flag definitions
require 'A/User.rb'
require 'A/match.rb'

class Command
  attr_reader :name, :flag, :syntax, :shorthelp, :minargs
  def initialize(name, flag, proto, syntax, shorthelp, help, minargs)
    @name = name
    @flag = flag
    @proto = proto
    @syntax = syntax
    @shorthelp = shorthelp
    @help = help
    @minargs = minargs
  end

  # Returns true on success, false on failure
  def run()
  end

  def sendhelp(u)
    @proto.do_NOTICE(u, "Help for #{@name}:")
    @proto.do_NOTICE(u, "Syntax: #{@syntax}")
    @proto.do_NOTICE(u, " ")
    @help.split("\n").each do |msg|
      @proto.do_NOTICE(u, msg.empty?() ? ' ' : msg)
    end
    @proto.do_NOTICE(u, "End of help.")
  end
end

# we'll go full java
class CommandChgHost < Command
  def initialize(proto)
    super('CHGHOST', 'h', proto, "CHGHOST nick newhost",
         'Changes a user\'s host',
"Changes the user's host temporarily.

Please supply a valid host, as we will update our internal state after
this operation and will not check for the actual validity of the host,
which our will do and reject the new host.",
         2)
  end

  def run(u, args)
    target = User.find_by_nick(args[0])
    if target == nil
      @proto.do_NOTICE(u, "Could not find user #{args[0]}.")
      return false
    end
    @proto.do_CHGHOST(target, args[1])
    target.dhost = args[1]
    @proto.do_NOTICE(u, "Changed the host of #{target.nick} to be #{args[1]}.")

    return true
  end
end

#class CommandForceAuth < Command
#  def initialize(proto)
#    super('FORCEAUTH', 'a', proto, "FORCEAUTH nick [account]",
#         "Forces authentication on a user",
#         'Forces a user to be authed for the given account.
#If no account is given, the nick will be assumed to be the same as the
#account name. Note that Atheme is very picky about the account name
#being correct, it can be found using /msg NickSERV INFO.',
#         1)
#  end

#  def run(u, args)
#    target = User.find_by_nick(args[0])
#    if target == nil
#      @proto.do_NOTICE(u, "Could not find user #{args[0]}.")
#      return false
#    end
#    acct = if args[1] != nil 
#             args[1]
#           else
#             target.nick
#           end
#    @proto.do_FORCEAUTH(target, acct)
#    @proto.do_NOTICE(u, "Changed the authname of #{target.nick} to be #{acct}.")

#    return true
#  end
#end

class CommandKill < Command
  def initialize(proto)
    super('KILL', 'k', proto, "KILL nick reason",
         'Kills a user anonymously',
         "Kills the given user with the given reason as a server, your nick will not be
shown; it will #{$config.options['logchan'] == '*' ? 'not be logged, either' : 'be logged, however.'}",
         2)
  end

  def run(u, args)
    nick = args.shift()
    target = User.find_by_nick(nick)
    if target == nil
      if nick.downcase() == $config.bot['nick'].downcase()
        @proto.do_NOTICE(u, "Could not find user #{nick}... As if. Nice try, but I'm above you.")
      else
        @proto.do_NOTICE(u, "Could not find user #{nick}.")
      end
      return false
    end

    if $config.has_flag(target, 'g')
      @proto.do_NOTICE(u, "#{target.nick} is a god, cowardly refusing to kill.")
      @proto.do_OPERWALL("#{u.nick} tried to kill #{target.nick}, HAHA OH WOW!")
      return false
    end
    @proto.do_SERVER_KILL(target, args.join(' '))
    @proto.do_NOTICE(u, "Terminated #{target.nick}.")

    return true
  end
end

class CommandGlobal < Command
  def initialize(proto)
    super('GLOBAL', 'n', proto, "GLOBAL message",
         'Sends a notice to all online users',
"All users will receive the message specified as a notice. Note that
all global notices are anonymous; nobody will know who sent them: Use
with greater caution than you'd exercise with normal services globals.",
         1)
  end

  def run(u, args)
    msg = args.join(' ')
    @proto.do_GLOBAL("[Global Notice] #{msg}")
    @proto.do_NOTICE(u, "Globaled '#{msg}'.")

    return true
  end
end

class CommandGetInfo < Command
  def initialize(proto)
    super('GETINFO', 'i', proto, "GETINFO nick",
         'Prints info about a user',
"Shows info about the given user, among those UID, nick/ident/host and
an uncensored channel list.",
         1)
  end

  def run(u, args)
    nick = args.shift()
    target = User.find_by_nick(nick)
    if target == nil
      @proto.do_NOTICE(u, "#{nick} not found.")
      return false
    end
    @proto.do_NOTICE(u, target.info_str())
    if target.channels.empty?()
      @proto.do_NOTICE(u, "No channels.")
    else
      cs = "Channels:"
      target.channels.each do |c|
        if (cs.length + c.name.length + 1) > 480
          cs << "\n"
        end
        cs << " " << c.name
      end

      cs.split("\n").each do |c|
        @proto.do_NOTICE(u, c)
      end
    end

    return true
  end
end

class CommandGeoIP < Command
  def initialize(proto)
    super('GEOLOC', 'i', proto, "GEOLOC nick",
         'Prints Geolocational info about a user',
"Shows a users Location by IP and their ASN information",
         1)
  end

  def run(u, args)
    nick = args.shift()
    target = User.find_by_nick(nick)
    if target == nil
      @proto.do_NOTICE(u, "#{nick} not found.")
      return false
    end

    @proto.do_NOTICE(u, target.geo_str())

    return true
  end
end

class CommandMode < Command
  def initialize(proto)
    super('MODE', 'm', proto, "MODE #channel modestr",
         'Forces a channel mode',
         "Changes the mode of the channel forcibly.
Make sure your mode string is valid or you might just nuke the entire
network; A doubts you want that.",
         2)
  end

  def run(u, args)
    cname = args.shift()
    target = Channel.find_by_name(cname)
    if target == nil
      @proto.do_NOTICE(u, "Could not find channel #{cname}.")
      return false
    end

    modestr = args.join(' ')
    @proto.do_SERVER_MODE(target, modestr)
    @proto.parse_modestr(target, modestr)
    @proto.do_NOTICE(u, "Changed modes of #{target.name}.")

    return true
  end
end

class CommandCheckBan < Command
  def initialize(proto)
    super('CHECKBAN', 'c', proto, "CHECKBAN nick [#channel ...]",
         'Checks a user against banlists',
         "Checks if the given user is banned. If no channel is/no channels are
given, all channels will be checked. Great fun, that.",
         1)
  end

  def run(u, args)
    nick = args.shift()
    target = User.find_by_nick(nick)
    if target == nil
      if nick.downcase() == $config.bot['nick'].downcase()
        @proto.do_NOTICE(u, "Could not find user #{nick}... As if. Nice try, but I'm above you.")
      else
        @proto.do_NOTICE(u, "Could not find user #{nick}.")
      end
      return false
    end

    cs = Channel.find_with_ban_against(target)
    if cs.empty?()
      @proto.do_NOTICE(u, "#{target.nick} has no bans! Yay!")
      return true
    end

    @proto.do_NOTICE(u, "Ban list for #{target.nick}:")
    cs.each do |c, b|
      banstr = if b.length > 1
                 "#{b[0]}!#{b[1]}@#{b[2]}"
               else
                 "#{b[0]}"
               end
      @proto.do_NOTICE(u, "#{target.nick} is banned from #{c.name} (#{banstr}).")
    end
    @proto.do_NOTICE(u, "End of ban list for #{target.nick}:")

    return true
  end
end

class CommandRehash < Command
  def initialize(proto)
    super('REHASH', 'd', proto, "REHASH",
         'Rehashes the configuration',
         "Reloads F/O/U:lines.",
         0)
  end

  def run(u, args)
    $config.parse_config(true)
    
    return true
  end
end

class CommandSet < Command
  def initialize(proto)
    super('SET', 'f', proto, "SET option value",
         'Changes F:lines',
"This command changes settings specified in F:lines. Note that these
changes are temporary and will be overwritten on the next REHASH if not
updated in the configuration file as well.",
         2)
  end

  def run(u, args)
    val = args[1]
    if $config.is_boolean_opt(args[0].downcase())
      val = (val.downcase() == 'true')
    end

    case args[0].downcase()
    when 'protocol'
      @proto.notice('You cannot change the protocol on-the-fly.')
    when 'resv'
      if val
        @proto.do_RESV($config.bot['nick'])
      else
        @proto.do_UNRESV($config.bot['nick'])
      end
    when 'logchan'
      if val != '*' && Channel.to_lower(val) != Channel.to_lower($config.options['logchan'])
        @proto.do_PART($config.options['logchan'])
        @proto.do_SJOIN(val)
      end
    end
    $config.options[args[0].downcase()] = val

    @proto.do_NOTICE(u, "Changed #{args[0].downcase()} to #{val}.")
    
    return true
  end
end

class CommandDie < Command
  def initialize(proto)
    super('DIE', 'd', proto, "DIE",
         'Global thermonuclear war',
         "Kills me and takes the cruel world with me.",
         0)
  end

  def run(u, args)
    msg = "GOODBYE CRUEL WORLD (DIE by #{u.nick})"
    @proto.do_QUIT(msg)
    @proto.do_SQUIT(msg)
    return true
  end
end

class CommandUserList < Command
  include Match

  def initialize(proto)
    super('USERLIST', 'i', proto, "USERLIST criterion argument ...",
         'List online users',
"Lists the currently online users. You are required to specify at least
one criterion. If you specify more criteria, they all must be matched
for a user to be listed.

Known criteria are:
  NICK    find by nick
  IDENT   find by ident
  DHOST   find by displayed host
  RHOST   find by real host
  IP      find by IP
  HOST    alias for RHOST, DHOST and IP with the given host
  GECOS   find by GECOS (aka ircname/real name); must be last argument
  SERVER  find by server name
  CHANNEL matches if the user is in the given channel

All criteria but CHANNEL may contain wildcards. USERLIST is
case-insensitive using ASCII, not RFC1459 casemapping!",
         2)
  end

  Criteria = %w{NICK IDENT DHOST RHOST GECOS IP HOST SERVER CHANNEL}

  def user_matches_criteria(u, criteria)
    if u == nil || criteria == nil
      return false
    end

    criteria.each do |c, v|
      case c.upcase()
      when 'NICK'
        return false unless Match.match(v, u.nick, true)
      when 'IDENT'
        return false unless Match.match(v, u.ident, true)
      when 'DHOST'
        return false unless Match.match(v, u.dhost, true)
      when 'RHOST'
        return false unless Match.match(v, u.rhost, true)
      when 'IP'
        return false unless Match.match(v, u.ip, true)
      when 'HOST'
        if !Match.match(v, u.dhost, true) &&
          !Match.match(v, u.rhost, true) &&
          !Match.match(v, u.ip, true)
          return false
        end
      when 'SERVER'
        return false unless Match.match(v, u.server.name, true)
      when 'CHANNEL'
        matched = false
        u.channels.each do |c|
          if !matched
            matched = Match.match(v, c.name, true) ? true : false
          end
        end
        return false unless matched
      when 'GECOS'
        return false unless Match.match(v, u.gecos, true)
      else
        # wtf, we should not be here
        return false
      end
    end

    return true
  end

  def run(u, args)
    # criterion => arg
    criteria = {}
    #require 'debugger'; debugger
    args.each_with_index do |arg, i|
      # Index starts at 0, which must be a criterion
      if i % 2 == 0
        criteria[arg] = nil
      else
        # GECOS eats all other arguments!
        last = args[i - 1]
        if last == 'GECOS'
          criteria[last] = args[i..-1].join(' ')
        end
        criteria[last] = arg
      end
    end

    # Kill invalid criteria off here to prevent flood and CPU time waste
    criteria.each_key do |c|
      if !Criteria.include?(c.upcase())
        @proto.do_NOTICE(u, "Unknown criterion #{c}.")
        return false
      end
    end

    hits = 0
    User.all().each do |target|
      if user_matches_criteria(target, criteria)
        hits += 1
        @proto.do_NOTICE(u, target.info_str())
      end
    end

    if hits == 0
      @proto.do_NOTICE(u, "No matches on #{User.all().length} users on the network.")
    else
      @proto.do_NOTICE(u, "Matched #{hits} out of #{User.all().length} users on the network.")
    end

    return true
  end
end

class CommandChanList < Command
  def initialize(proto)
    super('CHANLIST', 'i', proto, "CHANLIST #channel",
         'List users in a channel',
"Lists the users in a channel.",
         1)
  end

  def run(u, args)
    c = Channel.find_by_name(args[0])
    if c == nil
      @proto.do_NOTICE(u, "No such channel '#{args[0]}'.")
      return false
    else
      @proto.do_NOTICE(u, "Users in #{c.name}:")
      c.get_users.each do |user|
        @proto.do_NOTICE(u, user.info_str())
      end
      @proto.do_NOTICE(u, "End of CHANLIST.")
      return true
    end
  end
end

class CommandSvsNick < Command
  def initialize(proto)
    super('SVSNICK', 's', proto, "SVSNICK nick newnick",
         "Changes a user's nick",
"Changes a user's nick. Will not change a user to someone else's nick.",
         2)
  end

  def run(u, args)
    target = User.find_by_nick(args[0])
    if target == nil
      @proto.do_NOTICE(u, "Could not find user #{args[0]}.")
      return false
    end
    nick = args[1]

    if (nick =~ /^[a-z{}_\[\]|\\^`][a-z0-9{}_\[\]|\\^`-]*$/i) == 0
      if User.find_by_nick(nick) == nil
        @proto.do_RSFNC(target, args[1])
        @proto.do_NOTICE(u, "User #{args[0]}'s nick has been changed to #{args[1]}.")
        return true
      else
        @proto.do_NOTICE(u, "Someone is using #{args[1]}!")
        return false
      end
    else
      @proto.do_NOTICE(u, "'#{args[1]}' is not a valid nickname!")
      return false
    end
  end
end

class Commands
  attr_reader :commands

  def initialize(proto)
    @proto = proto
    @commands = [
      CommandChanList.new(proto),
      CommandCheckBan.new(proto),
      CommandChgHost.new(proto),
      CommandDie.new(proto),
#      CommandForceAuth.new(proto),
      CommandGetInfo.new(proto),
      CommandGlobal.new(proto),
      CommandKill.new(proto),
      CommandMode.new(proto),
      CommandRehash.new(proto),
      CommandSet.new(proto),
      CommandSvsNick.new(proto),
      CommandUserList.new(proto),
    ]
  end

  def find_command(name)
    @commands.each do |cmd|
      if cmd.name == name.upcase()
        return cmd
      end
    end
    return nil
  end
end

