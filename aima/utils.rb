#________________________________________________________
# Misc functions

def print_queens(table, header=nil, sep=' ', numfmt='%g')
  #    """Print a list of lists as a table, so that columns line up nicely.
  #    header, if specified, will be printed as the first row.
  #    numfmt is the format for all numbers; you might want e.g. '%6.2f'.
  #    (If you want different formats in differnt columns, don't use print_table.)
  #    sep is the separator between columns."""
  puts header if header
  ct=0
  while ct < table.length
    print "[ "
    table.each do |el| 
      letter = el==ct ? 'Q' : '.'
      print letter + sep
    end
    puts "]"
    ct += 1
  end
end

def print_table(table, header=nil, sep=' ', numfmt='%g')
  #    """Print a list of lists as a table, so that columns line up nicely.
  #    header, if specified, will be printed as the first row.
  #    numfmt is the format for all numbers; you might want e.g. '%6.2f'.
  #    (If you want different formats in differnt columns, don't use print_table.)
  #    sep is the separator between columns."""
  puts header if header
  puts table
  found = table.found
  ct=0
  if found!=nil
    while ct < found.length
      print "[ "
      found.each do |el| 
        letter = el==ct ? 'Q' : '.'
        print letter + sep
      end
      puts "]"
      ct += 1
    end
  end
end


#______________________________________________________________________________
# Queues: Stack, FIFOQueue, PriorityQueue
class Stack
  #    """Return an empty list, suitable as a Last-In-First-Out Queue."""
  def initialize()
    @A = []
  end
    
  def append(item)
    @A << item
  end
    
  def len
    return @A.length
  end
    
  def extend(items)
    @A.concat(items) if items.is_a?(Array)
    @A << items if !items.is_a?(Array)
  end
    
  def pop()        
    e = @A.pop
    #    if @start > 5 and @start > (@A.length)/2:
    #      @A = @A[@start]
    #      @start = 0
    #    end
    return e
  end
end

class Queue
  #    """Queue is an abstract class/interface. There are three types:
  #        Stack(): A Last In First Out Queue.
  #        FIFOQueue(): A First In First Out Queue.
  #        PriorityQueue(lt): Queue where items are sorted by lt, (default <).
  #    Each type supports the following methods and functions:
  #        q.append(item)  -- add an item to the queue
  #        q.extend(items) -- equivalent to: for item in items: q.append(item)
  #        q.pop()         -- return the top item from the queue
  #        len(q)          -- number of items in q (also q.__len())
  #    Note that isinstance(Stack(), Queue) is false, because we implement stacks
  #    as lists.  If Python ever gets interfaces, Queue will be an interface."""

  def initialize() 
    #TODO how do you force code to be abstract in ruby
    #abstract
  end

  def extend(items)
    for item in items
      append(item)
    end
  end
end

class FIFOQueue < Queue 
  #FIFO 
  def initialize()
    @A = []
    @start = 0
  end
    
  def append(item)
    @A << item
  end
    
  def len
    return @A.length - @start
  end
    
  def extend(items)
    #bpoint if items.is_a?(Node)
    @A.concat(items) if items.is_a?(Array)
    @A << items if !items.is_a?(Array)
  end
    
  def pop()        
    e = @A[@start]
    @start += 1
    #    if @start > 5 and @start > (@A.length)/2:
    #      @A = @A[@start]
    #      @start = 0
    #    end
    return e
  end
  
end

#class PriorityQueue(Queue)
##    """A queue in which the minimum (or maximum) element (as determined by f and
##    order) is returned first. If order is min, the item with minimum f(x) is
##    returned first; if order is max, then it is the item with maximum f(x)."""
#    def initialize(order=min, f=lambda x: x):
#        update(self, A=[], order=order, f=f)
#    def append(self, item):
#        bisect.insort(self.A, (self.f(item), item))
#    def __len__(self):
#        return len(self.A)
#    def pop(self):
#        if self.order == min:
#            return self.A.pop(0)[1]
#        else:
#            return self.A.pop()[1]