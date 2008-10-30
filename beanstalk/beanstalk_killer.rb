require 'cgi'
require 'beanstalk-client'

DEFAULT_PORT = 11300
SERVER_IP = '127.0.0.1'

beanstalks = []

puts "start"

1000.times do
    beanstalks << Beanstalk::Pool.new(["#{SERVER_IP}:#{DEFAULT_PORT}"])
end

puts beanstalks.length

puts "done"
