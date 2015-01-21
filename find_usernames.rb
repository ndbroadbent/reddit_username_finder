#!/usr/bin/env ruby
require 'rubygems'
require 'excon'
require 'thread'
require 'thwait'

# Adjust these constants to search for different
# characters / username lengths
# ------------------------------------------
CHARS = ('a'..'z').to_a # + ('0'..'9').to_a
CHAR_COUNT = 3
# ------------------------------------------

def random_username(len)
  (0...(len)).map { CHARS[rand(CHARS.size)] }.join
end

def account_status(username)
  # Perform a fast HEAD request first
  response = Excon.head("http://www.reddit.com/user/#{username}")
  return :taken if response.status == 200

  # Check username status
  response = Excon.post('http://www.reddit.com/api/check_username.json', body: "user=#{username}", :headers => { "Content-Type" => "application/x-www-form-urlencoded" })

  if response.body.include?("deleted")
    :deleted
  elsif response.body.include?("already taken")
    :taken
  else
    :available
  end
end

threads = []

puts "Searching for usernames!\n\n"

5.times do
  200.times do
    threads << Thread.new do
      username = random_username(CHAR_COUNT)

      case account_status(username)
      when :available
        print "\e[32m#{username}\e[0m   "
      when :taken
        print "\e[35m#{username}\e[0m   "
      when :deleted
        print "\e[31m#{username}\e[0m   "
      end
    end
  end

  ThreadsWait.all_waits(*threads)
end

puts "\n\nDone!"
