dir = File.expand_path(File.dirname(__FILE__))
unless($LOAD_PATH.member?(dir))
  $LOAD_PATH.unshift(dir)
end

require 'test/unit'
require 'eventmachine'
require 'zlib'
require 'yaml'
require 'ruby-debug'
require 'buffered_tokenizer_pastie'
require 'benchmark'

Thread.abort_on_exception = true

SERVER_PORT = 7999
SERVER_IP = '127.0.0.1'
TOKEN = "|DEFAULTDELIMITED|"
#check with different types of files compression varies a ton for txt vs compressed like mp3
FILE_NAME = './fake_development.log'
#FILE_NAME = './A_Work_in_Progress.mp3'
COMPRESS = false 
#COMPRESS = true

TIMES = 5

class EmClientExample < EventMachine::Connection
  
  def unbind
    puts "client connection has terminated"
  end

  def process(data)
    puts "client got data: #{data}"
    send_files() if data=="success"
    send(prepare("some_msg")) if data=="filesDone"
    send(prepare("quit")) if data=="ack"
    if(data=="goodbye")
      puts "Client successfully sent all data shutting down!!!!"
      EventMachine::stop_event_loop
    end
  end
  
  def send_files()
    puts "sending files"
    @files = Array.new(TIMES,[FILE_NAME, Time.now.to_s])
    send_files_loop  
  end

  def send_files_loop
    if @files && @files.length > 0
      file = @files.shift
      EM.next_tick do
        send_file(file[0],file[1])
        send_files_loop
      end
    else
      puts "done syncing files"
      send(prepare("files_completed"))
    end
  end
  
  def send_file(path,mtime)
    puts "Syncing "+path
    contents = File.read(File.expand_path(path))
    contents = Zlib::Deflate.deflate(contents,Zlib::BEST_SPEED) if COMPRESS
    send(prepare("send_file #{path}, #{mtime}, content:#{contents}"))  
  end
  
  def send(str)
    #puts "sending: #{str}"
    send_data str
  end

  def prepare(str)
    str+TOKEN
  end
  
  def self.push_start()
    EventMachine.connect(SERVER_IP,SERVER_PORT,self) do |c|
      c.send_files()
    end
  end
  
end

class EmClientExampleBadBuffer < EmClientExample
  
  attr_accessor :buffer
  
  def initialize(*args)
    super
    @buffer = DataBuffer.new
  end
  
  def receive_data(data)
    @buffer.append(data)
    while(command = @buffer.grab)
      process(command)
    end
  end

  def prepare(str)
    @buffer.prepare(str)
  end
  
end

class EmClientExampleBuffToken < EmClientExample
  
  def initialize(*args)
    super
    @recv_buffer = BufferedTokenizer.new(TOKEN)
  end
  
  def receive_data(data)
    @recv_buffer.extract(data).each do |m|
      process(m)
    end
  end
  
end

class EmClientExampleStreamBuffToken < EmClientExample
  
  def initialize(*args)
    super
    @recv_buffer = BufferedTokenizer.new(TOKEN)
  end

  def send_files_loop
    if @files && @files.length > 0
      file = @files.shift
      EM.next_tick do
        send_file(file[0],file[1])
      end
    else
      puts "done syncing files"
      send(prepare("files_completed"))
    end
  end
  
  def send_file(path,mtime)
    puts "Syncing "+path
    send("send_file #{path}, #{mtime}, content:")
    
    EM::Deferrable.future( stream_file_data(File.expand_path(path)) ) {
      send(prepare(""))
      send_files_loop
    }  
  end
  
  def receive_data(data)
    @recv_buffer.extract(data).each do |m|
      process(m)
    end
  end
  
end

class EmClientExamplePastie < EmClientExample
  
  def initialize(*args)
    super
    @recv_buffer = BufferedTokenizerPastie.new(TOKEN)
  end
  
  def receive_data(data)
    @recv_buffer.extract(data).each do |m|
      process(m)
    end
  end
  
end

class EmServerExample < EventMachine::Connection
  
  def post_init
    if(@signature)
      client = Socket.unpack_sockaddr_in(get_peername)
      puts "Received a new connection from #{client.last}:#{client.first}"
    end
  end

  def unbind
    puts "server connection has terminated\n"
  end

  def process(data)
    #puts "server: #{data[0..15]}"
    send(prepare("success")) if data=="login"
    send(prepare("filesDone")) if data=="files_completed"
    send(prepare("ack")) if data=="some_msg"
    if data.match(/^send_file/)
      #puts data[0..40]
      puts "received file" 
      start = data.index(", content:") + ", content:".length
      ender = data.length
      contents = data[start,ender]
      contents = Zlib::Inflate.inflate(contents) if COMPRESS
      file_contents = File.read(File.expand_path(FILE_NAME))
      if contents != file_contents
        puts "file was corrupted"
        puts "received length: #{contents.length} file lenght: #{file_contents.length}"
        #File.open(File.expand_path("~/copy.file"),"w") do |f|
        #  f << contents
        #end      
      end
    end
    if data=="quit"
      send(prepare("goodbye"))
      close_connection_after_writing 
    end
  end
  
  def prepare(str)
    str+TOKEN
  end
  
  def send(msg)
    #puts "server sent: #{msg}"
    send_data msg
  end
  
end

class EmServerExampleBadBuffer < EmServerExample

  def initialize(*args)
    super
    @buffer = DataBuffer.new
  end
  
  def receive_data(data)
    @buffer.append(data)
    while(command = @buffer.grab)
      process(command)
    end
  end
  
  def prepare(str)
    @buffer.prepare(str)
  end
  
end

class EmServerExampleBuffToken < EmServerExample
  
  def initialize(*args)
    super
    @recv_buffer = BufferedTokenizer.new(TOKEN)
  end
  
  def receive_data(data)
    @recv_buffer.extract(data).each do |m|
      process(m)
    end
  end
  
end

class EmServerExamplePastie < EmServerExample
  
  def initialize(*args)
    super
    @recv_buffer = BufferedTokenizerPastie.new(TOKEN)
  end
  
  def receive_data(data)
    @recv_buffer.extract(data).each do |m|
      process(m)
    end
  end
  
end

class DataBuffer
  FRONT_DELIMITER = "0x5b".hex.chr # '['
  BACK_DELIMITER = "0x5d".hex.chr #']'[0].to_s(16).hex.chr
  DELIMITER = "|#{FRONT_DELIMITER}#{FRONT_DELIMITER}#{FRONT_DELIMITER}GT_DELIM#{BACK_DELIMITER}#{BACK_DELIMITER}#{BACK_DELIMITER}#{BACK_DELIMITER}|"
  DELIM_ESCAPE = /#{Regexp.escape(DELIMITER)}/
    DELIM_ESCAPE_END = /#{Regexp.escape(DELIMITER)}\Z/
    
    def initialize
      @unprocessed = ""
      @commands = []
    end
    
    def grab
      new_messages = @unprocessed.split(DELIM_ESCAPE)
      while new_messages.length > 1
        @commands << new_messages.shift
      end
      msg_length = new_messages.length
      if msg_length > 0
        if msg_length == 1 && (@unprocessed=~DELIM_ESCAPE_END)
          @commands.push(new_messages.shift)
          @unprocessed = ""
        else
          #put the rest of the last statement back into the buffer
          while(cut=@unprocessed.index(DELIM_ESCAPE))
            @unprocessed = (@unprocessed[cut..@unprocessed.length]).sub(DELIMITER,"")
          end
        end
      end
      if @commands.length > 0
        return @commands.shift
      else 
        return nil
      end
    end
    
    def prepare(str)
      str.to_s+DELIMITER
    end
    
    def append(data)
      @unprocessed = @unprocessed + data
    end
    
  end
  
  class EmSendFileTest < Test::Unit::TestCase
    
    def test_placeholder
      assert true
    end

    def start_server(server_type)
      server_pid = fork {
        EventMachine::run do
          EventMachine::start_server SERVER_IP, SERVER_PORT, server_type
          puts "Server now accepting requests..."
        end
      }
      server_pid
    end

    def start_client(client_type)
      client_pid = fork {
        EventMachine::run { client_type.push_start() }
      }
      client_pid
    end

    def run_against_server_client(client_example, server_example)
      assert_nothing_raised do
        puts Benchmark.realtime {
          server_pid = start_server(server_example)
          #make sure server is up for client to connect to
          sleep(0.2)
          client_pid = start_client(client_example)
          sleep(0.2)
          
          Process.wait(client_pid)
          puts "client finished"
          
          #I don't know a clean way to end event machine take it down
          Process.kill('KILL',server_pid)
          Process.waitall
        }
        puts "##############################################################"
      end
    end
    
    def test_em_send_files_with_em_buffered_tokenizer
      puts "send files test with em buffered tokenizer"
      client_example = EmClientExampleBuffToken
      server_example = EmServerExampleBuffToken   
      run_against_server_client(client_example, server_example)
    end

    def test_em_stream_files_with_em_buffered_tokenizer
      puts "stream files test with em buffered tokenizer"
      if COMPRESS == true
        puts "stream file can't be used with compression"
      else
        client_example = EmClientExampleStreamBuffToken
        server_example = EmServerExampleBuffToken   
        run_against_server_client(client_example, server_example)
      end
    end
    
    def test_em_send_files_with_bad_tokenizer
      puts "send files test with our bad bueffered tokenizer"
      client_example = EmClientExampleBadBuffer
      server_example = EmServerExampleBadBuffer   
      run_against_server_client(client_example, server_example)
    end

    def test_em_send_files_with_pastie_tokenizer
      puts "send files test with the pastied tokenizer"
      client_example = EmClientExamplePastie
      server_example = EmServerExamplePastie
      run_against_server_client(client_example, server_example)
    end
    
  end
  
