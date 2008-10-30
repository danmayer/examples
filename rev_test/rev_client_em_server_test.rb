require 'test/unit'
require 'eventmachine'
require 'openssl'
require 'rev'
require 'rev/ssl'

Thread.abort_on_exception = true

SERVER_PORT = 7999
SERVER_IP = '127.0.0.1'
TIMES = 10

class RevClientExample < Rev::SSLSocket

#Swap the classes to try non SSL
# Rev::TCPSocket
  
  attr_accessor :sent_files

  def initialize(*args)
    super
    @sent_files = 0
  end

  def on_read(data)
    puts "data: #{data}"
    send_files() if data=="success"
    send("some_msg") if data=="filesDone"
    send("quit") if data=="ack"
    if(data=="goodbye")
      puts "Client successfully sent all data shutting down!!!!"
      self.evloop.stop
    end
  end

  def send_files()
    puts "sending files"
    @files = Array.new(TIMES,['./mona_lisa.jpg', Time.now.to_s])
    send_files_loop  
  end
  
  def send_files_loop

    #EXPOSE THE PROBLEM
    #Allow rev to sleep for awhile and it should pass
    #Sleep time needed seems to vary depending on the machine
    sleep(0.7)

    if @files && @files.length > 0
      @started_files = true
      file = @files.shift
      send_file(file[0],file[1])
      @sent_files += 1
    else
      @started_files = false
      puts "done syncing files"
      send("files_completed")
    end
  end

  # for Rev looping
  def on_write_complete()   
    if @started_files == true
      send_files_loop 
    end
  end
  
  def send_file(path,mtime)
    puts "Syncing "+path+" at " # + mtime.to_s
    contents = File.read(File.expand_path(path))
    send("send_file #{path}, #{mtime}, #{contents}")  
  end

  def send(str)
    write str
  end

  #uncomment for non SSL version
  #def on_connect
  #  send("login")
  #end

  def on_ssl_connect
    send("login")
  end

  def on_peer_cert(peer_cert) 
    devver_cert = File.join(File.dirname(__FILE__),"devvercert.pem")
    local_cert = OpenSSL::X509::Certificate.new( File.read(devver_cert) )
    if local_cert.public_key.to_s!=peer_cert.public_key.to_s
      puts "SSL certs don't match... closing for security" if @log
      self.evloop.stop
      raise "SSL certs don't match... closing for security"
    end
  end
  
  def self.push_start()
    client = RevClientExample.connect(SERVER_IP, SERVER_PORT)  
    client.attach(Rev::Loop.default)
    
    Rev::Loop.default.run
    puts "rev loop exited, sent #{client.sent_files} files"
    exit client.sent_files
  end

end

class ServerExample < EventMachine::Connection

  def initialize(*args)
    super
  end

  def post_init
    
    #comment out these lines to try non SSL
    devver_cert = File.join(File.dirname(__FILE__),"devvercert.pem")
    self.start_tls(:cert_chain_file => devver_cert, :private_key_file => devver_cert)

    if(@signature)
      client = Socket.unpack_sockaddr_in(get_peername)
      puts "EM Received a new connection" 
    end
  end

  def receive_data(data)
    #puts "server: #{data}" if !data.match(/^send_file/)
    send("success") if data=="login"
    send("filesDone") if data=="files_completed"
    send("ack") if data=="some_msg"
    puts "received file" if data.match(/^send_file/)
    if data=="quit"
      send("goodbye")
      close_connection_after_writing
    end
  end
  
  def send(msg)
    send_data msg
  end
  
end

class RevClientEmServerTest < Test::Unit::TestCase
  
  def test_rev_to_em
    sent_count = 0
    assert_nothing_raised do
      
      server_pid = fork {
        EventMachine::run {
          EventMachine::start_server SERVER_IP, SERVER_PORT, ServerExample
          puts "Now accepting requests..."
        }
      }
      #make sure server is up for client to connect to
      sleep(0.2)
      
      client_pid = fork {
        RevClientExample.push_start()
      }
      Process.wait(client_pid)
      sent_count = $?.exitstatus
      puts "client finished"

      #I don't know a clean way to end event machine take it down
      Process.kill('KILL',server_pid)
      Process.waitall
    end
    assert_equal TIMES, sent_count
  end

end
