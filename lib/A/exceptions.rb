# exceptions.rb: Exceptions to throw and catch

# This exception can be thrown by any operation trying to find a channel by any
# attribute.
class NoSuchChannelException < Exception
end

# This exception can be thrown by any operation trying to look up an UID.
class NoSuchUIDException < Exception
end

# Can be thrown if the user is a moron and messed up the config.
class InvalidConfigurationFieldCountException < Exception
end

