# A small gui for basic IM messaging (AOL only)

# Author::    Dan Mayer (mailto:dan<@t>devver.net)
# Site:: http://devver.net/blog
# Copyright:: Copyright (c) 2008 Dan Mayer
# License::   revised BSD license (http://www.opensource.org/licenses/bsd-license.php)
# Version::   0.0.1 (AKA a "alpha it sucks" version)
# Thanks::
# Ian Henderson for creating TOC, _why for Shoes, and
# Oliver for Gentle Reminder which I used to learn (as my template).


#You need to install net-toc with gem install net-toc
#then copy toc.rb into shoes/contents/ruby/lib/net for this to work in shoes
require 'net/toc'

Shoes.app :title => "IM Shoes", 
  :width => 370, :height => 560, :resizable => false do

  #ADD your own user and password here, should allow you to do this via GUI
  @user = 'urUser'
  @password = 'urPass'
  
  background green, :height => 40
  
  caption "IM Shoes", :margin => 8, :stroke => white
  
  stack :margin => 10, :margin_top => 10 do    
    para "Buddies", :stroke => red, :fill => yellow
    
    stack :margin_left => 5, :width => 1.0, :height => 200 do
      background white
      border white, :strokewidth => 3
      @gui_buddies = para
    end

     flow :margin_top => 10 do
       para "To"
       @send_to = edit_line(:margin_left => 10, :width => 180)
     end

     flow :margin_top => 10 do
       para "Message"
       @add = edit_line(:margin_left => 10, :width => 180)
       button("Send", :margin_left => 5)  do
         send_msg(@send_to.text, @add.text);
         @send_to.text = '';
         @add.text = '';
       end
     end
   end
  
  stack :margin_top => 10 do
    background darkgray
    para strong('Messages'), :stroke => white
  end

  @gui_messages = stack :width => 1.0, :height => 207

  def refresh_buddies
    @buddies = []
    @client.buddy_list.each_group { |g, b| @buddies = @buddies + b }
    
    @gui_buddies.replace *(
                           @buddies.map { |buddy|
                             [ buddy.screen_name, '  ' ] +
                             [ link('Message') { set_to buddy.screen_name } ] +
                             [ '  ' ] + [ "\n" ]
                           }.flatten
                           )
  end


  def refresh
    refresh_buddies
    refresh_msgs
  end

  def refresh_msgs
    @gui_messages.clear
    
    @gui_messages.append do
      background white
      
      @messages.keys.sort.reverse.each { |day|
        stack do
          background lightgrey
          para strong(day.strftime('%B %d, %Y')), :stroke => white
        end
        
        stack do
          inscription *(
                        ([@messages[day][0].to_s]+
                         [" "]+
                         [@messages[day][1].to_s]+
                         [" "]+
                         [link('Reply') { set_to(@messages[day][0].to_s) }]).flatten
                        )
        end    
        
      }
      
    end
  end


  def set_to(screen_name)
    @send_to.text = screen_name;
    
    refresh
  end

  def send_msg(to_name, msg)
    msg = msg.strip
    to_name = to_name.strip
    
    return if msg == ''
    return if to_name == ''
    
    to_buddy = @client.buddy_list.buddy_named(to_name )
    
    if to_buddy.available?
      to_buddy.send_im(msg) 
      @messages[Time.now]=[to_name,msg]
    end
    
    refresh_msgs
  end

  def load   
    @client = Net::TOC.new(@user, @password)
    @client.connect
    sleep 4
    @messages = {}
    
    @buddies = []
    @client.buddy_list.each_group { |g, b| @buddies = @buddies + b }
    
    @client.on_im() do |message, buddy, auto_response|
      @messages[Time.now]=[buddy.screen_name, message.gsub(/<\/?[^>]*>/, "")]
      #buddy.send_im("#{message} responce") 
      refresh_msgs
    end
    
    refresh
  end
  
  load
  
end
