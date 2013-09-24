# CharybdisProtocol: Deal with input from a Charybdis server.
# Note that this is also the reference implementation for protocol modules.
# Protocol modules always just parse a given line and return information for
# further processing. It does, however, instantiate objects.
# You will need a controlling instance to actually make sense of the output of
# methods.
#
# Author:: CuleX
require 'A/User.rb'
require 'A/Channel.rb'
require 'A/exceptions.rb'
require 'A/Server.rb'
require 'A/Protocol.rb'
require 'A/commands.rb'

class CharybdisProtocol < Protocol
  # For the non-TS6 literate:
  #   EX       - chmode +e
  #   IE       - chmode +I
  #   EUID     - Charybdis EUID, CHGHOST (without ENCAP), NICKDELAY
  #   SERVICES - Supports some services stuff. Used by ratbox, Charybdis
  #              does that as a dummy operation to enable things like umode +S.
  #   ENCAP    - ENCAPsulation of new commands to keep compatibility.
  #   QS       - QuitStorm - no recursive sending of messages on SQUIT. TS6
  #              requires it anyway though.
  #   RSFNC    - Understands our remote services forced nick change aka svsnick
  RequiredCapabs = %w{EX IE EUID SERVICES ENCAP QS RSFNC}
  attr_reader :lastping

  def parse_line(line)
    line.chomp!()
    source = nil
    colon_arg_pos = line.index(' :', 1)
    spaces_to_colon_arg = line[0 .. (colon_arg_pos ? colon_arg_pos : -1)].count(' ')
    parts = line.split(' ', spaces_to_colon_arg + 1)
    if parts[0][0] == ':'
      source = parts.shift()[1..-1]
    end

    command = parts.shift()
    if parts[-1] && parts[-1][0] == ':'
      parts[-1] = parts[-1][1..-1]
    end
    begin
      case command.upcase()
      when "ADMIN"
        ircsend(msg_ADMIN(source, parts), @conn)
      when "AWAY"
        ircsend(msg_AWAY(source, parts), @conn)
      when "BAN"
        ircsend(msg_BAN(source, parts), @conn)
      when "BMASK"
        ircsend(msg_BMASK(source, parts), @conn)
      when "CAPAB"
        ircsend(msg_CAPAB(source, parts), @conn)
      when "CHGHOST"
        ircsend(msg_CHGHOST(source, parts), @conn)
      when "CONNECT"
        ircsend(msg_CONNECT(source, parts), @conn)
      when "DLINE"
        ircsend(msg_DLINE(source, parts), @conn)
      when "ENCAP"
        ircsend(msg_ENCAP(source, parts), @conn)
      when "ERROR"
        ircsend(msg_ERROR(source, parts), @conn)
      when "EUID"
        ircsend(msg_EUID(source, parts), @conn)
      when "GLINE"
        ircsend(msg_GLINE(source, parts), @conn)
      when "GUNGLINE"
        ircsend(msg_GUNGLINE(source, parts), @conn)
      when "INFO"
        ircsend(msg_INFO(source, parts), @conn)
      when "INVITE"
        ircsend(msg_INVITE(source, parts), @conn)
      when "JOIN"
        ircsend(msg_JOIN(source, parts), @conn)
      when "JUPE"
        ircsend(msg_JUPE(source, parts), @conn)
      when "KICK"
        ircsend(msg_KICK(source, parts), @conn)
      when "KILL"
        ircsend(msg_KILL(source, parts), @conn)
      when "KLINE"
        ircsend(msg_KLINE(source, parts), @conn)
      when "KNOCK"
        ircsend(msg_KNOCK(source, parts), @conn)
      when "LINKS"
        ircsend(msg_LINKS(source, parts), @conn)
      when "LOCOPS"
        ircsend(msg_LOCOPS(source, parts), @conn)
      when "LUSERS"
        ircsend(msg_LUSERS(source, parts), @conn)
      when "MLOCK"
        ircsend(msg_MLOCK(source, parts), @conn)
      when "MODE"
        ircsend(msg_MODE(source, parts), @conn)
      when "MOTD"
        ircsend(msg_MOTD(source, parts), @conn)
      when "NICK"
        ircsend(msg_NICK(source, parts), @conn)
      when "NOTICE"
        ircsend(msg_NOTICE(source, parts), @conn)
      when "OPERWALL"
        ircsend(msg_OPERWALL(source, parts), @conn)
      when "PART"
        ircsend(msg_PART(source, parts), @conn)
      when "PASS"
        ircsend(msg_PASS(source, parts), @conn)
      when "PING"
        # Could be a remote PING -> end of burst
        # Join only here to join with proper TS if possible to get ops
        if !@joined_logchan && $config.options['logchan'] != '*' && $config.options['logchan'][0] == '#'
          @joined_logchan = true
          cname = $config.options['logchan']
          do_SJOIN(cname)
        end
        @lastping = Time.now()
        ircsend("PONG :#{parts[0]}", @conn)
      when "PONG"
        ircsend(msg_PONG(source, parts), @conn)
      when "PRIVMSG"
        ircsend(msg_PRIVMSG(source, parts), @conn)
      when "QUIT"
        ircsend(msg_QUIT(source, parts), @conn)
      when "RESV"
        ircsend(msg_RESV(source, parts), @conn)
      when "SAVE"
        ircsend(msg_SAVE(source, parts), @conn)
      when "SERVER"
        ircsend(msg_SERVER(source, parts), @conn)
      when "SID"
        ircsend(msg_SID(source, parts), @conn)
      when "SIGNON"
        ircsend(msg_SIGNON(source, parts), @conn)
      when "SJOIN"
        ircsend(msg_SJOIN(source, parts), @conn)
      when "SQUIT"
        ircsend(msg_SQUIT(source, parts), @conn)
      when "STATS"
        ircsend(msg_STATS(source, parts), @conn)
      when "SVINFO"
        ircsend(msg_SVINFO(source, parts), @conn)
        $burst = true
      when "TB"
        ircsend(msg_TB(source, parts), @conn)
      when "TIME"
        ircsend(msg_TIME(source, parts), @conn)
      when "TMODE"
        ircsend(msg_TMODE(source, parts), @conn)
      when "TOPIC"
        ircsend(msg_TOPIC(source, parts), @conn)
      when "TRACE"
        ircsend(msg_TRACE(source, parts), @conn)
      when "UID"
        ircsend(msg_UID(source, parts), @conn)
      when "UNKLINE"
        ircsend(msg_UNKLINE(source, parts), @conn)
      when "UNRESV"
        ircsend(msg_UNRESV(source, parts), @conn)
      when "UNXLINE"
        ircsend(msg_UNXLINE(source, parts), @conn)
      when "USERS"
        ircsend(msg_USERS(source, parts), @conn)
      when "VERSION"
        ircsend(msg_VERSION(source, parts), @conn)
      when "WALLOPS"
        ircsend(msg_WALLOPS(source, parts), @conn)
      when "WHOIS"
        ircsend(msg_WHOIS(source, parts), @conn)
      when "XLINE"
        ircsend(msg_XLINE(source, parts), @conn)
      else
        if $config.options['logchan'] != "*"
          ircsend("PRIVMSG #{$config.options['logchan']} :The fuck did we just get? #{command.upcase} is unhandled by my protocol.", @conn)
        end
        puts("!! Command '#{command.upcase}' is unhandled by my protocol.")
      end
    rescue NoMethodError => e
      puts("!! We dont handle #{command} yet!")
      if $config.options['debug']
        puts(e.inspect)
        puts(e.backtrace) 
      end
    end
  end

  # Overridden from Protocol.
  def get_services_modestr()
    return "+ioS"
  end

  # generates SJOIN for our user
  def sjoin_user(u, c)
    return ":#{@server.sid} SJOIN #{c.ts} #{c.name} + :@#{u.uid}"
  end

  # All message-receiving methods must be prefixed by msg_ and take the
  # following arguments:
  # source (String), args (String array, may be empty but never nil)

  # Creates a new CharybdisProtocol instance.
  # Arguments:
  # * our Server object
  # * the password to send to the uplink
  #
  # Returns an array of Strings to send for bursting.
  def initialize(server, conn)
    @joined_logchan = false
    @server = server
    @conn = conn
    @commandmanager = Commands.new(self)
    @seenuplinkname = false
    @lastping = Time.now()
  end

  # Returns the three numerics to be sent
  def msg_ADMIN(source, args)
    return ["256 #{source} :Administrative info for #{@server.name}:",
            "257 #{source} :The A Bot",
            "258 #{source} :btw, you're being owned"]
  end

  # Returns nil. We couldn't care less.
  def msg_AWAY(source, args)
    return nil # I don't care, get lost
  end

  # Receives a Charybdis BAN message. These are network-wide bans and only part
  # of what Charybdis speaks, not general TS6.
  #
  # We will not need to understand these, so, ignoring.
  def msg_BAN(source, args)
    return nil
  end

  # Receives a TS 6 BMASK message for bans/invites/exempts. We will want to
  # know that for CHECKBAN.
  #
  # Throws NoSuchChannelException if we don't have the channel internally
  # registered already.
  #
  # Returns nil
  def msg_BMASK(source, args)
    # :42X BMASK 1234567890 #x b :*!*@derp *!Mibbit@* ...
    c = Channel.find_by_name(args[1])
    if not c
      raise(NoSuchChannelException, "Couldn't find #{args[1]}")
    end

    ts = args[0].to_i()

    if c.ts < ts
      return nil
    end

    if args[2] != 'b' && args[2] != 'e'
      # We've "added" the entry, i.e., discarded what we didn't care about
      return nil
    end

    args[3].split(' ').each do |ban|
      c.add_ban(ban, args[2])
    end

    return nil
  end

  # Receives a TS6 CAPAB message and makes sure it matches what we want to
  # send.
  #
  # Returns nil if we're content, an ERROR exist string to send otherwise.
  def msg_CAPAB(source, args)
    capabs = args[0].split(' ')

    # We require these. Drop links that don't provide it.
    RequiredCapabs.each() do |capab|
      if !capabs.include?(capab)
        return "ERROR :Closing link (Missing capab #{capab})"
      end
    end

    return nil
  end

  # Receives a Charybdis CHGHOST message.
  # Side-effect: Updates the user's dhost
  # Returns nil.
  def msg_CHGHOST(source, args)
    u = User.find_by_uid(args[0])
    u.dhost = args[1]
    return nil
  end

  # Receives a TS6 CONNECT message.
  # Charybdis ts6-protocol wants us to wallop. We must send this from our
  # server, otherwise regular users will see it.
  # Returns a String to send for wallop-ing.
  def msg_CONNECT(source, args)
    u = User.find_by_uid(source)
    idiot = if u != nil
              u.nick
            else
              source
            end
    return ":#{@server.sid} WALLOPS :HAHA OH WOW, #{idiot}! I AM A SERVICE, YOU IDIOT!"
  end

  # Receives a Charybdis DLINE message. We don't care.
  # Returns nil.
  def msg_DLINE(source, args)
    return nil
  end

  # Receives ENCAP and handles it
  # Returns nil if we have nothing to respond, otherwise a String array of
  # things to send.
  def msg_ENCAP(source, args)
    # :UID/SID ENCAP * COMMAND params ...
    # We will never get CHGHOST here because we have EUID as capab
    case args[1]
    when 'CERTFP'
      u = User.find(source)
      if u != nil
        u.certfp = args[2]
        return nil
      end
    when 'SU'
      u = User.find(args[1])
      if u != nil
        u.su = args[2]
      end
    when 'LOGIN'
      u = User.find(source)
      if u != nil
        u.su = args[1]
      end
    else
      return nil
    end

    return nil
  end

  # Receives an ERROR message.
  #
  # Returns the error string we've got. We should probably quit after this.
  def msg_ERROR(source, args)
    return args[0]
  end

  # Receives an EUID message.
  #
  # Returns the newly created User object.
  def msg_EUID(source, args)
    # source: SID
    # parameters:
    # 0 - nickname
    # 1 - hopcount
    # 2 - nickTS
    # 3 - umodes
    # 4 - username
    # 5 - visible hostname
    # 6 - IP
    # 7 - UID
    # 8 - real hostname
    # 9 - account name
    # 10- gecos
    s = Server.find_by_sid(source)
    if $config.options['debug']
      puts("Got EUID from #{source}:")
      puts("Server: #{s.name}[#{s.sid}]: #{s.desc}")
      i = 0
      args.each do |arg|
        puts("args[#{i}] = #{arg}")
        i += 1
      end
    end
    u = User.new(s, args[7], args[0], args[4], args[5], args[8], args[6], args[2], args[3], args[10])
    u.su = args[9]
    s.usercount += 1
    return nil
  end

  # Receives an INFO message.
  #
  # Returns an array of strings to send. Numeric responses.
  def msg_INFO(source, args)
    return ["371 #{source} :This is A.",
            "371 #{source} :Well, you found me. Congratulations.",
            "374 #{source} :End of /INFO list"]
  end

  # Sink INVITE. We have no user object for our pseudoclient. Unlike logchan,
  # public channels matter, so we can't simply disregard the extra user (us),
  # risking a desync.
  def msg_INVITE(source, args)
    return nil
  end

  # Deals with JOIN messages.
  #
  # Returns nil.
  def msg_JOIN(source, args)
    u = User.find(source)
    if u == nil
      return nil
    end

    if args[0] == '0' && args.length == 1
      u.channels.each do |c|
        c.del_user(u)
      end
      u.part_all()
      return nil
    end

    # Ignoring TS rules since we don't even keep track of cmodes

    c = Channel.find_by_name(args[1])
    if c == nil
      c = Channel.new(args[1], args[0].to_i())
    end

    c.add_user(u)
    u.join(c)
    return nil
  end

  # Handles KICK messages.
  #
  # Returns nil.
  def msg_KICK(source, args)
    c = Channel.find_by_name(args[0])
    target = User.find(args[1])

    # Charybdis checks server-side and rejects kicks on +S clients, no need for
    # rejoin code here.

    # TS 0 very unlikely, simply accept it, esp. since our uplink checked
    c.del_user(target)
    target.part(c)
    return nil
  end

  # Handle incoming KILLs.
  # Kills for our psuedoclient are be impossible due to Chary's protection via
  # umode +S.
  #
  # Returns nil
  def msg_KILL(source, args)
    return nil
  end

  # Handle KNOCK.
  #
  # No fucks given, returns nil.
  def msg_KNOCK(source, args)
    return nil
  end

  # "Handle" LINKS.
  #
  # Tells the user to fuck off in a sendable string.
  def msg_LINKS(source, args)
    return ":#{@server.sid} NOTICE #{source} :We don't support LINKS. Please kindly die in a fire."
  end

  # Sink LOCOPS.
  #
  # nil
  def msg_LOCOPS(source, args)
    return nil
  end

  # Handle LUSERS
  #
  # Returns an array of strings to send
  def msg_LUSERS(source, args)
    return ["251 #{source} :here are 0 users and 1 invisible",
      "252 #{source} 1 :IRC Operators online",
      "255 #{source} :I have 1 clients and 1 server",
      "265 #{source} 1 1 :Current local users 1, max 1"]
  end

  # Sink MLOCK because we don't change modes. OperServ can do that.
  #
  # Returns nil
  def msg_MLOCK(source, args)
    return nil
  end

  # Handles MODE.
  #
  # Returns nil, updates the user info
  def msg_MODE(source, args)
    u = User.find(source)
    if u == nil
      # MODE for channel? Must be broken, fuck this
      return nil
    end
    adding = if args[1][0] == '+'
               true
             elsif args[1][0] == '-'
               false
             else
               nil
             end
    return nil if adding == nil

    # +o and +a are the only umodes we care about
    args[1].each_char do |c|
      if c == '+'
        adding = true
      elsif c == '-'
        adding = false
      elsif c == 'o'
        if adding and u.olevel != 'admin'
          u.olevel = 'oper'
        end
        if !adding
          u.isoper = false
          u.olevel = nil
        else
          u.isoper = true
        end
      elsif c == 'a'
        if adding
          u.olevel = 'admin'
          u.isadmin = true
        else
          u.isadmin = false
          u.olevel = nil
        end
      end
    end

    return nil
  end

  def msg_NICK(source, args)
    u = User.find(source)
    return nil unless u
    u.nick = args[0]
    u.ts = args[1].to_i()
    return nil
  end

  # Sink WALLOPS and OPERWALL.
  def msg_OPERWALL(source, args)
    return nil
  end

  def msg_WALLOPS(source, args)
    return nil
  end

  # Handle PASS message. We actually, unlike some other pseudoservers, do check
  # the password we get -- passwords must be symmetrical.
  #
  # Returns an ERROR string to send or nil
  def msg_PASS(source, args)
    # PASS linkage TS 6 :42X
    if args[0] != $config.uplink['password']
      return 'ERROR :Closing Link (Invalid password)'
    end

    @uplinksid = args[3]
  
    return nil
  end

  # Handle PART message. Check for permanent channels!
  #
  # Returns nil
  def msg_PART(source, args)
    # :UID PART #channel1,#channel2,... :optional message
    u = User.find_by_uid(source)
    args[0].split(' ').each do |cname|
      c = Channel.find_by_name(cname)
      next unless c

      c.del_user(u)
      u.part(c)

      if c.get_user_count() == 0 && !c.is_permanent?()
        c.obliterate()
      end
    end

    return nil
  end

  # Handle QUITs.
  #
  # Returns nil.
  def msg_QUIT(source, args)
    u = User.find(source)
    u.server.usercount -= 1
    u.obliterate() if u != nil
    return nil
  end

  # Sink SERVER. It's used to introduce TS5 servers (aka jupes) and the uplink
  # server. We care about neither.
  #
  # Returns nil.
  def msg_SERVER(source, args)
    if !@seenuplinkname
      # SERVER name 1 :desc
      Server.new(@uplinksid, args[0], args[2])
      @seenuplinkname = true
    end
    return nil
  end

  # Introduces a new real TS6 server.
  def msg_SID(source, args)
    # :uplinkSID SID name hops SID :desc
    Server.new(args[2], args[0], args[3])

    return nil
  end

  # Handles SQUIT.
  def msg_SQUIT(source, args)
    # SQUIT sid :reason
    if args[0] == @server.sid
      return "ERROR :SQUIT recieved, Shutting down..."
      @conn.close()
      exit(1)
    end
  end

  # Handles STATS.
  #
  # Returns an array with responses to send.
  def msg_STATS(source, args)
    # :UID STATS letter :targetSID
    u = User.find_by_uid(source)
    if u == nil
      return nil
    end

    if !u.isoper
      return ["481 #{source} :Permission Denied - You're not an IRC operator",
        "219 #{source} #{args[0]} :End of /STATS report"]
    end

    # We can assume targetSID is us; we have nowhere else to route it to
    ret = []
    case args[0]
    when 'o', 'O'
      #<07:01:47> :hydra.invalid 243 culex O *@* * fabio admin -1
      $config.opers.each do |oper|
        ret.push("243 #{source} O #{oper.to_stats_string()}")
      end
    end
   ret.push("219 #{source} #{args[0]} :End of /STATS report")
   return ret
  end

  # Handles SVINFO and sends our "burst" back.
  #
  # Returns an array containing our burst
  def msg_SVINFO(source, args)
    ret = [":#{$config.server.sid} EUID #{$config.bot['nick']} 1 #{Time.now().to_i()} #{get_services_modestr()} #{$config.bot['ident']} #{$config.bot['host']} 0 #{$config.server.sid}AAAAAA #{$config.bot['host']} * :The A Bot"]

    if $config.options['resv']
      ret.push(":#{$config.server.sid}AAAAAA ENCAP * RESV 0 #{$config.bot['nick']} 0 :Reserved for The A Bot")
    end

    return ret
  end

  # SJOIN, burst a channel creation or join a user with ops (from a server)
  #
  # :src SJOIN ts channel +nt :@00AAAAAAC
  def msg_SJOIN(source, args)
    c = Channel.find_by_name(args[1])
    if !c
      c = Channel.new(args[1], args[0])
    end
    offset = 0
    args[2].each_char do |c|
      case c
      when 'q', 'k', 'l', 'I', 'f', 'j', 'e', 'b', 'o', 'v'
        offset += 1
      end
    end
    parse_modestr(c, args[3..(3+offset)])
    if args[3 + offset] == nil
      # Can happen with +P channels
      return nil
    end
    args[3 + offset].split(" ").each do |user|
      # First number is start of UID because of SID definition
      idx = 0
      user.each_char do |c|
        case c
        when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
          break
        else
          idx += 1
        end
      end
      begin
        u = User.find_by_uid(user[idx..-1])
        c.add_user(u)
        u.join(c)
      rescue NoMethodError => e
        puts("Error getting UID (#{user[(idx - 1)..-1]} for idx=#{idx} and user=#{user}): #{e.inspect}")
      end
    end
    return nil
  end

  def parse_modestr(c, modes)
    adding = if modes[0][0] == '+'
               true
             elsif modes[0][0] == '-'
               false
             else
               nil
             end
    return nil if adding == nil

    offset = 0
    # Only modes we care about is +b, +e and +P
    # We do need to keep track of all other param modes for offset though
    modes[0].each_char do |char|
      case char
      when '+'
        adding = true
      when '-'
        adding = false
      when 'b'
        if adding
          c.add_ban(modes[1 + offset], 'b')
        else
          c.del_ban(modes[1 + offset], 'b')
        end
        offset += 1
      when 'e'
        if adding
          char.add_ban(modes[1 + offset], 'e')
        else
          char.del_ban(modes[1 + offset], 'e')
        end
        offset += 1
      when 'q', 'k', 'l', 'I', 'f', 'j', 'o', 'v'
        offset += 1
      when 'P'
        c.set_permanent(adding)
        # Removing, check if it needs to die, can happen with services
        if !adding && c.get_user_count() == 0
          c.obliterate()
        end
      end
    end

    return nil
  end

  # Handles TMODE, channel mode changes.
  #
  # Returns nil.
  def msg_TMODE(source, args)
    # :UID/SID TMODE 1234567890 #channel +b root!*@* ...
    c = Channel.find_by_name(args[1])
    return nil if c == nil
    if args[0].to_i() > c.ts
      return nil
    end

    parse_modestr(c, args[2..-1])

    return nil
  end

  # Sink TOPIC.
  def msg_TOPIC(source, args)
    return nil
  end

  def msg_WHOIS(source, args)
    # :2UNAAACPA WHOIS 00SAAAAAA :A
    # Ignore whois requests for nicks that aren't A.
    if args[1] != $config.bot['nick']
      return "401 #{source} #{args[1]} :No such nick"
    end
    return ["311 #{source} #{$config.bot['nick']} #{$config.bot['ident']} #{$config.bot['host']} * :The A Bot",
      "312 #{source} #{$config.bot['nick']} #{@server.name} :#{@server.desc}",
      "313 #{source} #{$config.bot['nick']} :is a Network Service",
      "318 #{source} #{args[1]} :End of WHOIS"]
  end

  # The big ones, PRIVMSG and NOTICE.
  #
  # For simplicity's sake, msg_NOTICE returns msg_PRIVMSG(source, parts)
  # Passes to commands.rb for actual processing.
  def msg_PRIVMSG(source, args)
    u = User.find(source)
    if u == nil
      # um what? BAIL
      return nil
    end

    if args[0][0] == "#"
      # Bail!
      return nil
    end

    if !u.isoper && $config.options['require_oper']
      ret = ":#{$config.server.sid} WALLOPS :Non-oper #{u.nick}!#{u.ident}@#{u.rhost} [#{u.ip}] tried to access me!"
      if $config.options['logchan'] != '*'
        ret.push(":#{@server.sid}AAAAAA PRIVMSG #{$config.options['logchan']} :#{u.nick}!#{u.ident}@#{u.rhost}: #{cmd} #{oldargs.join(' ')}")
      end

      return ret
    end

    args = args[1].split(' ')
    cmd = args.shift().upcase()

    if cmd == "HELP"
      if args.length > 0
        c = @commandmanager.find_command(args[0])
        if c == nil
          return ":#{@server.sid}AAAAAA NOTICE #{u.uid} :Could not find command #{args[0]}."
        else
          begin
            c.sendhelp(u)
          rescue
            return ":#{@server.sid}AAAAAA NOTICE #{u.uid} :No help available for #{args[0]}."
          end
          return nil
        end
      end

      ret = [":#{@server.sid}AAAAAA NOTICE #{u.uid} :Commands known to me:"]
      @commandmanager.commands.each do |c|
        ret.push(sprintf(":%sAAAAAA NOTICE %s : %-10s %s", @server.sid, u.uid,
                        c.name, c.shorthelp))
      end
      ret.push(":#{@server.sid}AAAAAA NOTICE #{u.uid} :End of command listing.")
      return ret
    end

    c = @commandmanager.find_command(cmd)
    if c == nil
      return ":#{@server.sid}AAAAAA NOTICE #{u.uid} :Could not find command #{cmd}."
    end

    if !$config.has_flag(u, c.flag)
      return ":#{@server.sid}AAAAAA NOTICE #{u.uid} :You do not have the required flag #{c.flag} to use #{cmd}."
    end

    if c.minargs > args.length
      return ":#{@server.sid}AAAAAA NOTICE #{u.uid} :#{cmd} requires #{c.minargs} arguments, got #{args.length}."
    end

    # Copy of args in case commands mess with the args array
    oldargs = args.dup()
    success = c.run(u, args)
    # Only use "good" runs for logging
    if !$config.options['abuse'] && success
      do_OPERWALL("#{u.nick} used #{c.name} (#{oldargs.join(' ')})")
    end

    if $config.options['logchan'] != '*'
      return ":#{@server.sid}AAAAAA PRIVMSG #{$config.options['logchan']} :#{u.nick}!#{u.ident}@#{u.rhost}: #{cmd} #{oldargs.join(' ')}"
    end
    return nil
  end

  def msg_NOTICE(s, a) # Because shorthand, considering this is a -tiny- function
    return msg_PRIVMSG(s, a)
  end

  ### Actions. Must be the same for all proto modules

  def do_NOTICE(u, msg)
    ircsend(":#{@server.sid}AAAAAA NOTICE #{u.is_a?(User) ? u.uid : u} :#{msg}", @conn)
  end

  def do_GLOBAL(msg)
    Server.all().each do |s|
      ircsend(":#{@server.sid}AAAAAA NOTICE $$#{s.name} :#{msg}", @conn)
    end
  end

  def do_PRIVMSG(u, msg)
    ircsend(":#{@server.sid}AAAAAA PRIVMSG #{u.is_a?(User) ? u.uid : u} :#{msg}", @conn)
  end

  def do_CHGHOST(u, host)
    ircsend(":#{@server.sid}AAAAAA CHGHOST #{u.uid} #{host}", @conn)
  end

  def do_SERVER_KILL(u, reason)
    ircsend(":#{@server.sid} KILL #{u.uid} :#{@server.name} (#{reason})", @conn)
  end

  def do_OPERWALL(msg)
    ircsend(":#{@server.sid}AAAAAA OPERWALL :#{msg}", @conn)
  end

  def do_QUIT(msg)
    ircsend(":#{@server.sid}AAAAAA QUIT :Quit: #{msg}", @conn)
  end

  def do_SQUIT(msg)
    ircsend(":#{@server.sid} SQUIT #{@uplinksid} :#{msg}", @conn)
    @conn.close()
    puts("Death by DIE, shutting down...")
    exit()
  end

  def do_FORCEAUTH(u, acct)
    ircsend(":#{@server.sid} ENCAP * SU #{u.uid} #{acct}", @conn)
  end

  def do_SERVER_MODE(c, modes)
    ircsend(":#{@server.sid} TMODE #{c.ts} #{c.name} #{modes}", @conn)
  end

  def do_RESV(target)
    ircsend(":#{$config.server.sid}AAAAAA ENCAP * RESV 0 #{target} 0 :Reserved for The A Bot", @conn)
  end

  def do_UNRESV(target)
    ircsend(":#{$config.server.sid}AAAAAA ENCAP * UNRESV #{target}", @conn)
  end

  def do_PART(c)
    if !c.is_a?(Channel)
      c = Channel.find_by_name(c)
      return if c == nil
    end

    ircsend(":#{$config.server.sid}AAAAAA PART #{c.name}", @conn)
  end

  def do_SJOIN(c)
    cname = c
    if !c.is_a?(Channel)
      c = Channel.find_by_name(cname)
    end

    ircsend(":#{$config.server.sid} SJOIN #{c ? c.ts : Time.now().to_i()} #{c ? c.name : cname} + :@#{$config.server.sid}AAAAAA", @conn)
  end

  def do_RSFNC(u, n)
    if !u.is_a?(User)
      u = User.find_by_nick(u)
      return if u == nil
    end

    return if n == nil
    now = Time.now().to_i()
    ircsend(":#{$config.server.sid} ENCAP #{u.server.name} RSFNC #{u.uid} #{n} #{now} #{u.ts}", @conn)
    u.nick = n
    u.ts = now
  end
end

