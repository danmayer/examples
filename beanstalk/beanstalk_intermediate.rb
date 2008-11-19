require 'beanstalk-client.rb'
require 'ruby-debug'

DEFAULT_PORT = 11300
SERVER_IP = '127.0.0.1'
#beanstalk will order the queues based on priority, with the same priority
#it acts FIFO, in a later example we will use the priority
#(higher numbers are higher priority)
DEFAULT_PRIORITY = 65536
#TTR is time for the job to reappear on the queue.
#Assuming a worker died before completing work and never called job.delete
#the same job would return back on the queue (in TTR seconds)
TTR = 3

class BeanBase

  #To work with multiple queues you must tell beanstalk which queues
  #you plan on writing to (use), and which queues you will reserve jobs from
  #(watch). In this case we also want to ignore the default queue
  #you need a different queue object for each tube you plan on using or
  #you can switch what the tub is watching and using a bunch, we just keep a few
  #queues open on the tubes we want.
  def get_queue(queue_name)
    @queue_cache ||= {}
    if @queue_cache.has_key?(queue_name)
      return @queue_cache[queue_name]
    else
      queue = Beanstalk::Pool.new(["#{SERVER_IP}:#{DEFAULT_PORT}"])
      queue.watch(queue_name)
      queue.use(queue_name)
      queue.ignore('default')
      @queue_cache[queue_name] = queue
      return queue
    end
  end

  #this will take a message off the queue, and process it with the block
  def take_msg(queue)
    msg = queue.reserve
    #by calling ybody we get the content of the message and convert it from yml
    body = msg.ybody
    if block_given?
      yield(body)
    end
    msg.delete
  end

  def results_ready?(queue)
    queue.peek_ready!=nil
  end
  
end

class BeanDistributor < BeanBase
  
  def initialize(chunks,points_per_chunk)
    @chunks = chunks
    @points_per_chunk = points_per_chunk
    @messages_out = 0
    @circle_count = 0
  end

  def get_incoming_results(queue)
    if(results_ready?(queue))
      result = nil
      take_msg(queue) do |body|
        result = body.count
      end
      @messages_out -= 1
      print "." #display that we received another result
      @circle_count += result
    else
      #do nothing
    end
  end

  def start_distributor
    request_queue = get_queue('requests')
    results_queue = get_queue('results')
    #put all the work on the request queue
    puts "distributor sending out #{@messages} jobs"
    @chunks.times do |num|
      msg = BeanRequest.new(1,@points_per_chunk)
      #Take our ruby object and convert it to yml and put it on the queue
      request_queue.yput(msg,pri=DEFAULT_PRIORITY, delay=0, ttr=TTR)
      @messages_out += 1
      #if there are results get them if not continue sending out work
      get_incoming_results(results_queue)
    end
 
    while @messages_out > 0
      get_incoming_results(results_queue)
    end
    npoints = @chunks * @points_per_chunk
    pi = 4.0*@circle_count/(npoints)
    puts "\nreceived all the results our estimate for pi is: #{pi}"
  end

end

class BeanWorker < BeanBase

  def initialize()
  end
  
  def write_result(queue, result)
    msg = BeanResult.new(1,result)
    queue.yput(msg,pri=DEFAULT_PRIORITY, delay=0, ttr=TTR)
  end
  
  def in_circle
    #generate 2 random numbers see if they are in the circle
    range = 1000000.0
    radius = range / 2
    xcord = rand(range) - radius
    ycord = rand(range) - radius
    if( (xcord**2) + (ycord**2) <= (radius**2) )
      return 1
    else
      return 0
    end
  end

  def start_worker
    request_queue = get_queue('requests')
    results_queue = get_queue('results')
    #get requests and do the work until the worker is killed
    while(true)
      result = 0
      take_msg(request_queue) do |body|
        chunks = body.count
        chunks.times { result += in_circle}
      end
      write_result(results_queue,result)
    end
    
  end
  
end

############
# These are just simple message classes that we pass using beanstalks
# to yml and from yml functions.
############
class BeanRequest
  attr_accessor :project_id, :count
  def initialize(project_id, count=0)
    @project_id = project_id
    @count = count
  end
end

class BeanResult
  attr_accessor :project_id, :count
  def initialize(project_id, count=0)
    @project_id = project_id
    @count = count
  end
end

#how many different jobs we should do
chunks = 100
#how many points to calculate per chunk
points_per_chunk = 10000
#how many workers should we have
#(normally different machines, in our example fork them off)
workers = 5

# Most of the time you will have two entirely separate classes
# but to make it easy to run this example we will just fork and start our server
# and client separately. We will wait for them to complete and check
# if we received all the messages we expected.
puts "starting distributor"
server_pid = fork {
  BeanDistributor.new(chunks,points_per_chunk).start_distributor
}

puts "starting client(s)"
client_pids = []
workers.times do |num|
  client_pid = fork {
    BeanWorker.new.start_worker
  }
  client_pids << client_pid
end

Process.wait(server_pid)
#take down the clients
client_pids.each do |pid| 
  Process.kill("HUP",pid)
end
