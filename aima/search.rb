# Author: Dan Mayer
# Email: Dan@pretheory.com
# 
# Working on code and problems from AI a modern approach, in Ruby. For fun and
# to get better with the Ruby programming language.
#

require "./utils.rb"

INFINITY = 999999999999999999

def bpoint
  require 'ruby-debug'
  Debugger.start
  debugger
end

class Problem
  #    """The abstract class for a formal problem.  You should subclass this and
  #    implement the method successor, and possibly __init__, goal_test, and
  #    path_cost. Then you will create instances of your subclass and solve them
  #    with the various search functions."""
  attr_accessor :initial, :goal
  
  def initialize(initial, goal=nil)
    #        """The constructor specifies the initial state, and possibly a goal
    #        state, if there is a unique goal.  Your subclass's constructor can add
    #        other arguments."""
    @initial = initial
    @goal = goal
  end
        
  def successor(state)
    #        """Given a state, return a sequence of (action, state) pairs reachable
    #        from this state. If there are many successors, consider an iterator
    #        that yields the successors one at a time, rather than building them
    #        all at once. Iterators will work fine within the framework."""
        
    #TODO how do you force code to be abstract in ruby
    #abstract
  end
    
  def goal_test(state)
    #        """Return True if the state is a goal. The default method compares the
    #        state to self.goal, as specified in the constructor. Implement this
    #        method if checking against a single self.goal is not enough."""
    return state == @goal
  end
    
  def path_cost(c, state1, action, state2)
    #        """Return the cost of a solution path that arrives at state2 from
    #        state1 via action, assuming cost c to get up to state1. If the problem
    #        is such that the path doesn't matter, this function will only look at
    #        state2.  If the path does matter, it will consider c and maybe state1
    #        and action. The default method costs 1 for every step in the path."""
    return c + 1
  end

  def value()
    #        """For optimization problems, each state has a value.  Hill-climbing
    #        and related algorithms try to maximize this value."""

    #TODO how do you force code to be abstract in ruby
    #abstract
  end

end


#______________________________________________________________________________
# Node to implement trees and such    
class Node
  #    """A node in a search tree. Contains a pointer to the parent (the node
  #    that this is a successor of) and to the actual state for this node. Note
  #    that if a state is arrived at by two paths, then there are two nodes with
  #    the same state.  Also includes the action that got us to this state, and
  #    the total path_cost (also known as g) to reach the node.  Other functions
  #    may add an f and h value; see best_first_graph_search and astar_search for
  #    an explanation of how the f and h values are handled. You will not need to
  #    subclass this class."""
  attr_accessor :state, :parent, :action, :path_cost, :depth
  
  def initialize(state, parent=nil, action=nil, path_cost=0)
    #        "Create a search tree Node, derived from a parent by an action."
    #    update(state=state, parent=parent, action=action, 
    #      path_cost=path_cost, depth=0)
    @state=state
    @parent=parent
    @action=action 
    @path_cost=path_cost
    @depth=0
    @depth = parent.depth + 1 if parent
  end
            
            
  def repr()
    return "<Node %s>" % (@state)
  end
    
  def path()
    #        """Create a list of nodes from the root to this node."""
    # Isn't this backwards???
    x, result = self, [self]
    while x.parent
      result.append(x.parent)
      x = x.parent
    end
    return result
  end

  #TODO this could be wrong go over again
  def expand(problem)
    #        "Return a list of nodes reachable from this node. [Fig. 3.8]"
    expand = []
    #bpoint
    problem.successor(@state).each do | action_succ |
      act = action_succ[0]
      next_act = action_succ[1]
      expand << Node.new(next_act, self, act,problem.path_cost(@path_cost, @state, act, next_act))
    end
    return expand
  end

end


#______________________________________________________________________________
## Uninformed Search algorithms

def tree_search(problem, fringe)
  #    """Search through the successors of a problem to find a goal.
  #    The argument fringe should be an empty queue.
  #    Don't worry about repeated paths to a state. [Fig. 3.8]"""
  #    Since we dont worry about repeated paths this can lead to infinite loops
  fringe.append(Node.new(problem.initial))
  while fringe.len > 0
    node = fringe.pop()
    return node if problem.goal_test(node.state) if node
    fringe.extend(node.expand(problem)) if node
  end
  return nil
end

def breadth_first_tree_search(problem)
  #    "Search the shallowest nodes in the search tree first. [p 74]"
  return tree_search(problem, FIFOQueue.new)
end
    
def depth_first_tree_search(problem)
  #    "Search the deepest nodes in the search tree first. [p 74]"
  return tree_search(problem, Stack.new)
end

def graph_search(problem, fringe)
  #    """Search through the successors of a problem to find a goal.
  #    The argument fringe should be an empty queue.
  #    If two paths reach a state, only use the best one. [Fig. 3.18]"""
  closed = []
  fringe.append(Node.new(problem.initial))
  while fringe.len > 0
    node = fringe.pop()
    if node #loop wrong do we need these? len > 1?
      if problem.goal_test(node.state) 
        return node
      end
      if !closed.member?(node.state)
        closed << node.state
        fringe.extend(node.expand(problem))    
      end
    end
  end
  return nil
end

def breadth_first_graph_search(problem)
  #"Search the shallowest nodes in the search tree first. [p 74]"
  return graph_search(problem, FIFOQueue.new)
end
    
def depth_first_graph_search(problem)
  #    "Search the deepest nodes in the search tree first. [p 74]"
  return graph_search(problem, Stack.new)
end
  
def depth_limited_search(problem, limit=50)
  #"[Fig. 3.12]"
  # Would this not be more elegant with an exception instead of 'cutoff'?
  # Or would an exception work better for the _successful_ case? ;-)
  def recursive_dls(node, problem, limit)
    cutoff_occurred = false
    if problem.goal_test(node.state):
      return node
    elsif node.depth == limit:
      return 'cutoff'
    else
      for successor in node.expand(problem)
        result = recursive_dls(successor, problem, limit)
        if result == 'cutoff'
          cutoff_occurred = true
        elsif result != nil
          return result
        end
      end
    end
    if cutoff_occurred
      return 'cutoff'
    else
      return nil
    end
  end
  # Body of depth_limited_search:
  return recursive_dls(Node.new(problem.initial), problem, limit)
end

def iterative_deepening_search(problem)
  #    "[Fig. 3.13]"
  [0..656].each do |depth| # for depth in xrange(sys.maxint)
    result = depth_limited_search(problem, depth)
    if result!='cutoff'
      return result
    end
  end
end

#______________________________________________________________________________
# Informed (Heuristic) Search

#def best_first_graph_search(problem, f)
##    """Search the nodes with the lowest f scores first.
##    You specify the function f(node) that you want to minimize; for example,
##    if f is a heuristic estimate to the goal, then we have greedy best
##    first search; if f is node.depth then we have depth-first search.
##    There is a subtlety: the line "f = memoize(f, 'f')" means that the f
##    values will be cached on the nodes as they are computed. So after doing
##    a best first search you can examine the f values of the path returned."""
#    f = memoize(f, 'f')
#    return graph_search(problem, PriorityQueue(min, f))
#end

# greedy_best_first_graph_search = best_first_graph_search
# Greedy best-first search is accomplished by specifying f(n) = h(n).
    
#def astar_search(problem, h=None):
#    """A* search is best-first graph search with f(n) = g(n)+h(n).
#    You need to specify the h function when you call astar_search.
#    Uses the pathmax trick: f(n) = max(f(n), g(n)+h(n))."""
#    h = h or problem.h
#    def f(n):
#        return max(getattr(n, 'f', -infinity), n.path_cost + h(n))
#    return best_first_graph_search(problem, f)

#______________________________________________________________________________
## Other search algorithms

#def recursive_best_first_search(problem):
#    "[Fig. 4.5]"
#    def RBFS(problem, node, flimit):
#        if problem.goal_test(node.state): 
#            return node
#        successors = expand(node, problem)
#        if len(successors) == 0:
#            return None, infinity
#        for s in successors:
#            s.f = max(s.path_cost + s.h, node.f)
#        while True:
#            successors.sort(lambda x,y: x.f - y.f) # Order by lowest f value
#            best = successors[0]
#            if best.f > flimit:
#                return None, best.f
#            alternative = successors[1]
#            result, best.f = RBFS(problem, best, min(flimit, alternative))
#            if result is not None:
#                return result
#    return RBFS(Node(problem.initial), infinity)
#
#
#def hill_climbing(problem):
#    """From the initial node, keep choosing the neighbor with highest value,
#    stopping when no neighbor is better. [Fig. 4.11]"""
#    current = Node(problem.initial)
#    while True:
#        neighbor = argmax(expand(node, problem), Node.value)
#        if neighbor.value() <= current.value():
#            return current.state
#        current = neighbor
#
#def exp_schedule(k=20, lam=0.005, limit=100):
#    "One possible schedule function for simulated annealing"
#    return lambda t: if_(t < limit, k * math.exp(-lam * t), 0)
#
#def simulated_annealing(problem, schedule=exp_schedule()):
#    "[Fig. 4.5]"
#    current = Node(problem.initial)
#    for t in xrange(sys.maxint):
#        T = schedule(t)
#        if T == 0:
#            return current
#        next = random.choice(expand(node. problem))
#        delta_e = next.path_cost - current.path_cost
#        if delta_e > 0 or probability(math.exp(delta_e/T)):
#            current = next
#
#def online_dfs_agent(a):
#    "[Fig. 4.12]"
#    pass #### more
#
#def lrta_star_agent(a):
#    "[Fig. 4.12]"
#    pass #### more
#
##______________________________________________________________________________
## Genetic Algorithm
#
def genetic_search(problem, fitness_fn, ngen=1000, pmut=0.0, n=20)
  #    """Call genetic_algorithm on the appropriate parts of a problem.
  #    This requires that the problem has a successor function that generates
  #    reasonable states, and that it has a path_cost function that scores states.
  #    We use the negative of the path_cost function, because costs are to be
  #    minimized, while genetic-algorithm expects a fitness_fn to be maximized."""
  #states = [s for (a, s) in problem.successor(problem.initial_state)[:n]]
  states = problem.successor(problem.initial_state)
  random.shuffle(states)
  #fitness_fn = lambda s: - problem.path_cost(0, s, nil, s)
  #fitness_fn = {-problem.path_cost(0, s, nil, s)}
  return genetic_algorithm(states, fitness_fn, ngen, pmut)
end

def genetic_algorithm(population, fitness_fn, ngen=1000, pmut=0.0)
  #    """[Fig. 4.7]"""
  def reproduce(p1, p2)
    c = random.randrange(len(p1))
    return p1[c] + p2[c]
  end

  for i in range(ngen)
    new_population = []
    for i in len(population):
      p1, p2 = random_weighted_selections(population, 2, fitness_fn)
      child = reproduce(p1, p2)
      if random.uniform(0,1) > pmut
        child.mutate()
      end
      new_population.append(child)
      population = new_population
    end
  end
  return argmax(population, fitness_fn)
end

def random_weighted_selection(seq, n, weight_fn)
  #  """Pick n elements of seq, weighted according to weight_fn.
  #    That is, apply weight_fn to each element of seq, add up the total.
  #    Then choose an element e with probability weight[e]/total.
  #    Repeat n times, with replacement. """
  totals = []
  runningtotal = 0
  seq.each do |item|
    runningtotal += send(weight_fn,item)
    totals<<(runningtotal)
  end
  selections = []
  for s in (0..n).to_a
    r = rand(totals.length)
    for i in [0..seq.length]
      if totals[i] > r
        selections.append(seq[i])
        break
      end
    end
  end
  return selections
end

#_____________________________________________________________________________
# The remainder of this file implements examples for the search algorithms.

#______________________________________________________________________________
# Graphs and Graph Problems

class Graph
  #    """A graph connects nodes (verticies) by edges (links).  Each edge can also
  #    have a length associated with it.  The constructor call is something like:
  #        g = Graph({'A': {'B': 1, 'C': 2})   
  #    this makes a graph with 3 nodes, A, B, and C, with an edge of length 1 from
  #    A to B,  and an edge of length 2 from A to C.  You can also do:
  #        g = Graph({'A': {'B': 1, 'C': 2}, directed=False)
  #    This makes an undirected graph, so inverse links are also added. The graph
  #    stays undirected; if you add more links with g.connect('B', 'C', 3), then
  #    inverse link is also added.  You can use g.nodes() to get a list of nodes,
  #    g.get('A') to get a dict of links out of A, and g.get('A', 'B') to get the
  #    length of the link from A to B.  'Lengths' can actually be any object at 
  #    all, and nodes can be any hashable object."""
  attr_accessor :locations
  
  def initialize(dict={}, directed=true)
    @dict = dict
    @directed = directed
    @locations = {}
    make_undirected() if !directed
  end

  def make_undirected()
    #"Make a digraph into an undirected graph by adding symmetric edges."
    @dict.keys().each do |a|
      #TODO distance should have a value sometimes?
      @dict[a].keys().each do |b|
        distance = @dict[a][b]
        connect1(b, a, distance)
      end
    end
  end

  def connect(a, b, distance=1)
    #        """Add a link from A and B of given distance, and also add the inverse
    #        link if the graph is undirected."""
    connect1(a, b, distance)
    connect1(b, a, distance) if !@directed
  end        

  def connect1(a, b, distance=1)
    #        "Add a link from A to B of given distance, in one direction only."
    #bpoint
    @dict[a] = {} if !@dict.has_key?(a)
    @dict[a][b] = distance
  end

  def get(a, b=nil)
    #        """Return a link distance or a dict of {node: distance} entries.
    #        .get(a,b) returns the distance or None;
    #        .get(a) returns a dict of {node: distance} entries, possibly {}."""
    @dict[a] = {} if !@dict.has_key?(a)
    links = @dict[a]
    if b==nil 
      return links
    else
      return links.get(b)
    end
  end

  def nodes()
    #        "Return a list of nodes in the graph."
    return @dict.keys()
  end
end
    
  
def UndirectedGraph(dict=nil)
  #      "Build a Graph where every edge (including future ones) goes both ways."
  return Graph.new(dict, false)
end
  
def RandomGraph(nodes=range(10), min_links=2, width=400, height=300,
    curvature=nil)
  #                                curvature=lambda: random.uniform(1.1, 1.5)
  #      """Construct a random graph, with the specified nodes, and random links.
  #      The nodes are laid out randomly on a (width x height) rectangle.
  #      Then each node is connected to the min_links nearest neighbors.
  #      Because inverse links are added, some nodes will have more connections.
  #      The distance between nodes is the hypotenuse times curvature(),
  #      where curvature() defaults to a random number between 1.1 and 1.5."""
  g = UndirectedGraph()
  g.locations = {}
  ## Build the cities
  for node in nodes:
    g.locations[node] = [rand(width), rand(height)]
  end
  ## Build roads from each city to at least min_links nearest neighbors.
  for i in range(min_links)
    for node in nodes
      if (len(g.get(node)) < min_links)
        here = g.locations[node]
        def distance_to_node(n)
          return 99999999 if (n.is_a?(node) || g.get(node,n)) 
          return distance(g.locations[n], here)
        end
                      
        neighbor = argmin(nodes, distance_to_node)
        d = distance(g.locations[neighbor], here) * curvature()
        g.connect(node, neighbor, int(d)) 
      end
    end
  end
  return g
end

class GraphProblem < Problem
  #"The problem of searching a graph from one node to another."
  def initialize(initial, goal, graph)
    #@problem = Problem.new(initial, goal)
    super(initial, goal)
    @graph = graph
  end

  def successor(a)
    #"Return a list of (action, result) pairs."
    retval = []  
    @graph.get(a).keys().each do |b|
      retval << [b,b]
    end
    return retval
    #return [(B, B) for B in @graph.get(A).keys()]
    #end
  end

  def path_cost(cost_so_far, a, action, b)
    get_val = @graph.get(a,b)  
    if get_val
      return cost_so_far + get_val
    else
      return INFINITY
    end
  end

  def h(node)
    #"h function is straight-line distance from a node's state to goal."
    locs = @graph.locations
    if locs
      return int(distance(locs[node.state], locs[@goal]))
    else
      return INFINITY
    end
  end
end

#
# Nqueens first actual problem
#
class NQueensProblem < Problem 
  #  """The problem of placing N queens on an NxN board with none attacking
  #    each other.  A state is represented as an N-element array, where the
  #    a value of r in the c-th entry means there is a queen at column c,
  #    row r, and a value of None means that the c-th column has not been
  #    filled in yet.  We fill in columns left to right."""
  
  attr_accessor :n_queens, :initial
  
  def initialize(n_queens)
    @n_queens = n_queens
    @initial = Array.new(n_queens) #[None] * N
  end

  def successor(state) 
    #"In the leftmost empty column, try all non-conflicting rows."
    if state[(state.length-1)] != nil:
      return [] # All columns filled; no successors
    else
      def place(col, row, state)
        new = Array.new(state) #.copy # copy the state
        new[col] = row
        return new
      end
      col = state.index(nil)
      attempts = []
      if col!=nil
        #TODO possible N-1 error
        (0...@n_queens).to_a.each do |row|
          #bpoint
          attempts << [row, place(col, row, state)] if !conflicted(state, row, col)
        end
      end
      return attempts
    end
  end
                    
  def conflicted(state, row, col)
    #"Would placing a queen at (row, col) conflict with anything?"
    #TODO possible n-1 one error
    if col!=nil
      (0...col).to_a.each do |c|
        #bpoint
        return true if conflict(row, col, state[c], c)        
      end
    end
    return false
  end
          
  def conflict(row1, col1, row2, col2)
    #"Would putting two queens in (row1, col1) and (row2, col2) conflict?"
    ## same row  ## same column ## same \ diagonal ## same / diagonal
    return (row1 == row2 || col1 == col2 || row1-col1 == row2-col2 || row1+col1 == row2+col2) 
  end
    
  def goal_test(state)
    #"Check if all columns filled, no conflicts."
    return false if state[(state.length-1)] == nil 
    #TODO possible n-1 error
    (0...state.length).to_a.each do |c|
      return false if conflicted(state, state[c], c)               
    end
    return true
  end
    
end

#______________________________________________________________________________
## Code to compare searchers on various problems.
class InstrumentedProblem < Problem
  #    """Delegates to a problem, and keeps statistics."""

  def initialize(problem) 
    @problem = problem
    @initial = problem.initial #shouldn't have to do this if method override correct
    @succs = @goal_tests = @states = 0
    @found = nil
  end
        
  def successor(state)
    #        "Return a list of (action, state) pairs reachable from this state."
    result =  @problem.successor(state)
    @succs += 1
    @states += result.length
    return result
  end
    
  def goal_test(state)
    #        "Return true if the state is a goal."
    @goal_tests += 1
    result = @problem.goal_test(state)
    @found = state if result 
            
    return result
  end
  
  #TODO doesn't work in ruby like python, besides method missing how in ruby?  
  #don't know what part of method calling to override to do this. Method missing doesn't work because
  # problem has .intial method, we need to catch calls on this object and if .initial pass to
  # problem.initial
  #  def getattr(attr)
  #    if['succs', 'goal_tests', 'states'].exist(attr)
  #      return self.send(attr)
  #    else
  #      return @problem.send(attr)
  #    end
  #  end 
  #   def method_missing(m, *args)
  #     puts "***************************************************"
  #     bpoint
  #     return @problem if m=='problem'
  #     return @problem.send(m) if @problem
  #   end  
  
  def found
    return @found
  end

  def to_s
    return "successors | goal tests | states | found \n"+'<%4d/%4d/%4d/%s>' % [@succs, @goal_tests, @states, ' true'] if @found!=nil
    return "successors | goal tests | states | found \n"+'<%4d/%4d/%4d/%s>' % [@succs, @goal_tests, @states, ' false'] if @found==nil
    # str(@found)[0:4])
  end
 
end
  
def compare_searchers(problems, header, searchers=[:breadth_first_tree_search,
      :breadth_first_graph_search, :depth_first_graph_search,
      :depth_limited_search]) #TODO :iterative_deepening_search missing a search here
  def run(searcher, problem)
    p = InstrumentedProblem.new(problem)
    result = send(searcher,p)
    return p
  end
  problems.each do |p|
    searchers.each do |s| 
      table = run(s,p)
      print_table(table, header)
    end
  end
end

def compare_graph_searchers()
  
  romania = UndirectedGraph({
      "A"=>{"Z"=>75, "S"=>140, "T"=>118},
      "B"=>{"U"=>85, "P"=>101, "G"=>90, "F"=>211},
      "C"=>{"D"=>120, "R"=>146, "P"=>138},
      "D"=>{"M"=>75},
      "E"=>{"H"=>86},
      "F"=>{"S"=>99},
      "H"=>{"U"=>98},
      "I"=>{"V"=>92, "N"=>87},
      "L"=>{"T"=>111, "M"=>70},
      "O"=>{"Z"=>71, "S"=>151},
      "P"=>{"R"=>97},
      "R"=>{"S"=>80},
      "U"=>{"V"=>142}})
  
  romania.locations = {
    "A"=>{91, 492},    "B"=>{400, 327},    "C"=>{253, 288},   "D"=>{165, 299}, 
    "E"=>{562, 293},    "F"=>{305, 449},    "G"=>{375, 270},   "H"=>{534, 350},
    "I"=>{473, 506},    "L"=>{165, 379},    "M"=>{168, 339},   "N"=>{406, 537}, 
    "O"=>{131, 571},    "P"=>{320, 368},    "R"=>{233, 410},   "S"=>{207, 457}, 
    "T"=>{94, 410},    "U"=>{456, 350},    "V"=>{509, 444},   "Z"=>{108, 531}}

  australia = UndirectedGraph({
      "T"=>{},
      "SA"=>{"WA"=>1, "NT"=>1, "Q"=>1, "NSW"=>1, "V"=>1},
      "NT"=>{"WA"=>1, "Q"=>1},
      "NSW"=>{"Q"=>1, "V"=>1}})

  australia.locations = {
    "WA"=>{120, 24}, "NT"=>{135, 20}, "SA"=>{135, 30}, 
    "Q"=>{145, 20}, "NSW"=>{145, 32}, "T"=>{145, 42}, "V"=>{145, 37}}
  
  #  compare_searchers([GraphProblem.new('Q', 'T', australia)],
  #    'Searcher, Romania(A,B)')
  
  compare_searchers([GraphProblem.new('A', 'B', romania),
      GraphProblem.new('O', 'N', romania),
      GraphProblem.new('Q', 'WA', australia)],
    'Searcher, Romania(A,B), Romania(O, N), Australia')
end

def weight_fn(x)
  return (x * x)
end

puts "Start program"
  
prob = NQueensProblem.new(5)
inst_prob = InstrumentedProblem.new(prob)

#breadth_first_tree_search(inst_prob)
#depth_first_tree_search(inst_prob)
#breadth_first_graph_search(inst_prob)
#depth_first_graph_search(inst_prob)
#iterative_deepening_search(inst_prob)

#compare_searchers([prob],"N Queens Board")
#compare_graph_searchers()
 
puts random_weighted_selection((0..10).to_a, 3, :weight_fn)

table = inst_prob

if(table.found!=nil)
  puts table.found.inspect
  puts table
  print_table(table,"N Queens Board")
end
  
puts "End program"
