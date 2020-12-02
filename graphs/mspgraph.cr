# This class implements an msp-graph that can be produced by the two operations
# parallel composition (u), and series composition (x). N^+ and N^- are computed automatically.
# This also computes 'made_of', which can be used to retrace the steps with which this msp-graph
# was built. This is really helpful later when computing solutions for SSG and SSGW.
class Mspgraph
  # The weights of the vertices
  getter nodes : Hash(String, Int32)
  getter edges : Array(Array(String))
  # The expression by which this msp-graph was built
  getter mspexpr : String

  getter predecessors : Hash(String, Array(String))
  getter successors : Hash(String, Array(String))

  # [left side component, right side component] => operator
  # When the msp-graph is only a single node, there is no right side component
  # This is, more or less, an msp-tree as described in the paper (page 15).
  getter made_of : Hash(Array(Mspgraph), Symbol)

  def initialize(name : String, weight : Int32 = 0)
    unless name =~ /v\d+/
      raise "Error with node #{name}: nodes must be named 'v[number]'."
    end

    @nodes = {name => weight}
    @edges = Array(Array(String)).new
    @mspexpr = name
    @predecessors = {name => Array(String).new}
    @successors = {name => Array(String).new}
    @made_of = Hash(Array(Mspgraph), Symbol).new
    @made_of[[self]] = :create

    # puts "Created mspgraph with msp-expression '#{@mspexpr}'"
  end

  protected def initialize(@nodes, @edges, @mspexpr, @made_of)
    # Removes parentheses around single node msp-expressions, e.g. (v1) => v1
    @mspexpr = @mspexpr.gsub(/\((v\d+)\)/, "\\1", true)
    @predecessors = Hash(String, Array(String)).new
    @successors = Hash(String, Array(String)).new
    @nodes.keys.each do |node|
      @predecessors[node] = compute_predecessors(node)
      @successors[node] = compute_successors(node)
    end

    # puts "Created mspgraph with msp-expression '#{@mspexpr}'"
  end

  def sources
    @nodes.reject { |name, weight| !@predecessors[name].empty? }
  end

  def sinks
    @nodes.reject { |name, weight| !@successors[name].empty? }
  end

  def add_weights(weights : Array(Int32))
    if weights.size != @nodes.keys.size
      raise "Number of weights doesn't match number of nodes! Expected #{@nodes.keys.size}, got #{weights.size}."
    end
    @nodes.keys.sort_by { |name| name[1..-1].to_i }.each_with_index do |key, i|
      @nodes[key] = weights[i]
    end

    @made_of.keys.each do |graphs|
      graphs.each do |graph|
        graph.nodes.keys.each do |name|
          graph.nodes[name] = @nodes[name]
        end
      end
    end
  end

  # Parallel composition
  def pc(other : Mspgraph)
    check_unique_names(other)

    return Mspgraph.new(
      @nodes.merge(other.nodes),
      @edges + other.edges,
      "(#{@mspexpr}) u (#{other.mspexpr})",
      @made_of.merge(other.made_of).merge({[self, other] => :u})
    )
  end

  # Series composition
  def sc(other : Mspgraph)
    check_unique_names(other)

    return Mspgraph.new(
      @nodes.merge(other.nodes),
      @edges + other.edges + Array.product(sinks.keys, other.sources.keys),
      "(#{@mspexpr}) x (#{other.mspexpr})",
      @made_of.merge(other.made_of).merge({[self, other] => :x})
    )
  end

  private def check_unique_names(other : Mspgraph)
    @nodes.keys.each do |vertice|
      if other.nodes.keys.includes?(vertice)
        raise "Nodes not unique! #{vertice} appears at least twice in would be msp-expression (#{@mspexpr}) + (#{other.mspexpr})."
      end
    end
  end

  private def compute_predecessors(node : String)
    predecessors = Array(String).new

    @edges.each do |edge|
      predecessors << edge[0] if edge[1] == node
    end

    return predecessors
  end

  private def compute_successors(node : String)
    successors = Array(String).new

    @edges.each do |edge|
      successors << edge[1] if edge[0] == node
    end

    return successors
  end
end
