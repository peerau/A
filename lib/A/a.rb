require 'A/Config.rb'
require 'A/CharybdisProtocol.rb'
require 'socket'
require 'monitor'

class Connection
  def initialize()
    @server = TCPSocket.new($config.uplink['host'], $config.uplink['port'])
  end

  def gets()
    @server.gets()
  end

  def close()
    @server.close()
  end
end

class SSLConnection < Connection
  require 'openssl'

  def initialize()
    super()

    ctx = OpenSSL::SSL::SSLContext.new()
    ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @server = OpenSSL::SSL::SSLSocket.new(@server, ctx)
    @server.sync = true
    @server.connect()
  end

  def send(text)
    @server.syswrite(text + "\r\n")
  end
end

class PlainTextConnection < Connection
  def send(text)
    @server.send(text + "\r\n", 0)
  end
end

class PingTimer
  def initialize(proto)
    extend MonitorMixin
    @proto = proto
    @run = true

    @t = Thread.new() do
      t = Time.now()

      while is_running()
        t += 120
        sleep(t - Time.now) rescue nil
        check_ping()
      end
    end
  end

  def stop()
    synchronize() do
      @run = false
    end
    @t.join()
  end

  def is_running?()
    synchronize() do
      return @run
    end
  end

  def check_ping()
    tdelta = (Time.now() - @proto.lastping).to_i()
    if tdelta >= 240
      synchronize() do
        @proto.do_SQUIT("Ping timeout (#{tdelta})")
      end
    end
  end
end

def start_A()
  # Config
  path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "etc", "A.conf"))
  begin
    # Our configuration is global. Spheal with it.
    $config = AConfig.new(path)
  rescue Errno::ENOENT
    puts("Couldn't find #{path}")
    exit 1
  rescue InvalidConfigurationFieldCountException => e
    puts("Error parsing configuration file: #{e.message}")
    exit 1
  rescue Exception => e
    puts("Caught exception while reading configuration: #{e.inspect}")
    puts(e.backtrace)
    exit 1
  end

  # Protocol
  if $config.options['protocol'].downcase == "charybdis"
    pseudostart(CharybdisProtocol)
  else
    puts("No valid F:protocol line. quitting")
    exit 1
  end

  # GeoIP
  if $config.options['geoip']
    require 'geoip'
    $geoip = GeoIP.new(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "etc", "geoip", "GeoLiteCityv6.dat")))
  else
    puts("!! GeoIP not enabled..")
end

def pseudostart(proto)
  $burst = false
  conn = if $config.uplink['ssl']
           SSLConnection.new()
         else
           PlainTextConnection.new()
         end
  protocol = proto.new($config.server, conn)
  ircsend(["PASS #{$config.uplink['password']} TS 6 :#{$config.server.sid}",
               "CAPAB :IE EX EUID ENCAP SERVICES RSFNC SAVE QS",
               "SERVER #{$config.server.name} 1 :#{$config.server.desc}"], conn)
  PingTimer.new(protocol)
  while line = conn.gets()
    if $config.options['debug']
      puts(">> #{line}")
    end
    protocol.parse_line(line)
  end
end

def ircsend(command, conn)
  return if command == nil
  if command.kind_of?(Array)
    command.each do |line|
      if $config.options['debug']
        puts("<< #{line}")
      end
      conn.send(line)
    end
  elsif command.kind_of?(String)
    if $config.options['debug']
      puts("<< #{command}")
    end
    conn.send(command)
  end
end

