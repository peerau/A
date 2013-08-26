#!/usr/bin/env ruby
# run.rb: Main entry point for the A utility service.
#
# First of all, do what gems would usually do for us -- we don't want to
# pollute the system, though, so we'll stay in our directory. We need to set
# $. to a value of ../lib/ starting from run.rb

# Do not push; our libraries always take precedence, therefore unshift.
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")))

require 'A/a.rb'

start_A()

