# Config.rb: Read a configuration file and provide meaningful access.
require 'A/exceptions.rb'
require 'A/User.rb'
require 'A/Server.rb'
require 'A/match.rb'

class Oper
  include Match
  attr_reader :flags

  def initialize(userhost, certfp, acctname, flags)
    raise(ArgumentError, "user@host must include @ sign") if !userhost.include?('@')
    uh = userhost.split('@')
    @ident = uh[0]
    @host = uh[1]
    @certfp = (certfp.empty?() || certfp == '*') ? nil : certfp
    @account = (acctname.empty?() || acctname == '*') ? nil : acctname
    @flags = flags
  end

  # Checks if the given user has access to A
  # Arguments:
  # * User object
  def can_access(u)
    if $config.options['debug']
      puts("ident: #{@ident} vs. #{u.ident}")
      puts(" host: #{@host} vs. #{u.rhost}")
      puts(" cert: #{@certfp} vs. #{u.certfp}")
      puts(" acct: #{@account} vs. #{u.su}")
      puts("matc1: #{Match.match(@ident, u.ident, true)}")
      puts("matc2: #{Match.match(@host, u.rhost, true)}")
      puts(" cert: #{(u.certfp && @certfp && u.certfp == @certfp)}")
      puts(" acct: #{u.su && @account && u.su == @account}")
    end
    #identmatch = match(@ident, u.ident, true)
    #hostmatch = match(@host, u.rhost, true)
    #certfpmatch = u.certfp && @certfp && u.certfp
    ret = Match.match(@ident, u.ident, true) && (Match.match(@host, u.rhost, true) ||
                                                  Match.match(@host, u.ip, true))
      ((u.certfp && @certfp && u.certfp == @certfp) ||
      (u.su && @account && u.su == @account)) &&
      # Invalid O:line
      !(!@account && !@certfp)

    return ret
  end

  def to_stats_string()
    "#{@ident}@#{@host} #{@certfp ? @certfp : '*'} #{@account ? @account : '*'} #{@flags}"
  end
end

# Configuration file gateway.
class AConfig
  attr_reader :server, :vhost, :ulines, :options, :uplink, :bot, :opers, :levels

  # argument count for line type
  ArgumentCount = {'M' => 6, 'O' => 4, 'U' => 1, 'C' => 4, 'L' => 2, 'F' => 2}
  BooleanOptions = %w{require_oper debug abuse resv levels}

  def open_config()
    @f.close() if @f != nil
    @f = File.open(@path, 'r')
  end

  # Parses the configuration file.
  # Arguments:
  # * Are we rehashing?
  def parse_config(rehash)
    open_config() if rehash
    @opers = []
    @ulines = []
    @options = {}
    
    while true
      line = @f.gets("\n")
      break if line == nil
      line.chomp!()
      next if line.empty?() || line[0] == '#'
      # O:lines need special treatment because of IPv6
      fields = []
      fields = line.split(':')
      if line.start_with?('O') && fields.length > ArgumentCount['O']
        uh = fields[1..-4].join(':')
        fields.insert(uh)
      end
      char = fields.shift()
      seen = []

      # In case we remove *:lines at some point, be backwards-compatible.
      if ArgumentCount[char] == nil
        puts("Warning: I have no idea how to parse a #{char}:line.")
        next
      end

      if ArgumentCount[char] != fields.length
        raise(InvalidConfigurationFieldCountException,
              "#{char}:line needs #{ArgumentCount[char]} args, got #{fields.length}.")
      end

      case char
      when 'M'
        next if rehash
        @server = Server.new(fields[5], fields[0], fields[2])
        @vhost = fields[1]
        @bot = {'nick' => fields[3], 'ident' => fields[4], 'host' => fields[0]}
      when 'O'
        @opers.push(Oper.new(fields[0], fields[1], fields[2], fields[3]))
      when 'U'
        @ulines.push(fields[0])
      when 'C'
        next if rehash
        @uplink = {'host' => fields[0], 'password' => fields[1],
          'port' => fields[2].to_i(), 'ssl' => (fields[3] == 'true')}
      when 'L'
        @levels = {'oper' => fields[0], 'admin' => fields[1]}
      when 'F'
        val = fields[1]
        val = (fields[1] == 'true') if BooleanOptions.include?(fields[0])
        @options[fields[0]] = val
      end
    end

    @options['logchan'] = '*' if @options['logchan'] == nil
  end

  # Reads a configuration file.
  # Arguments:
  # * A file path as String
  def initialize(path)
    @f = nil
    @path = path
    open_config()
    @bot = []
    parse_config(false)
  end

  # Returns true if the given user has the given flag and permission to use A.
  # Flag may be nil to ask if A is supposed to respond at all
  def has_flag(u, f)
    @opers.each do |oper|
      if oper.can_access(u)
        puts("flags: #{oper.flags}") if $config.options['debug']
        ret = oper.flags.include?(f) || oper.flags.include?('*')
      end
    end

    if !ret
      if $config.options['levels']
        if u.isoper || u.isadmin
          puts("lflags: #{$config.levels[u.olevel]}")
  	      ret = $config.levels[u.olevel].include?(f)
        end
      end
    end
    
    return ret
  end

  def is_boolean_opt(opt)
    BooleanOptions.include?(opt)
  end
end

