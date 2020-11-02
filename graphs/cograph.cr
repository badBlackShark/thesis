# This class implements a cograph that can be produced by the three operations
# disjoint union (+), series composition (x), and order composition (/). N^+ and N^- are computed
# automatically.
# This also computes 'made_of', which can be used to retrace the steps with which this cograph
# was built. This is really helpful in later computing solutions for SSG and SSGW.
class Cograph
  # The weights of the vertices
  getter nodes : Hash(String, Int32)
  getter edges : Array(Array(String))
  # The expression by which this cograph was built
  getter dicoexpr : String

  getter predecessors : Hash(String, Array(String))
  getter successors : Hash(String, Array(String))

  # [left side component, right side component] => operator
  # When the cograph is only a single node, there is no right side component
  # This is, more or less, a di-co-tree as described in the paper (page 8).
  getter made_of : Hash(Array(Cograph), Symbol)

  def initialize(name : String, weight : Int32 = 0)
    unless name =~ /v\d+/
      raise "Error with node #{name}: nodes must be named 'v[number]'."
    end

    @nodes = {name => weight}
    @edges = Array(Array(String)).new
    @dicoexpr = name
    @predecessors = Hash(String, Array(String)).new
    @successors = Hash(String, Array(String)).new
    @made_of = Hash(Array(Cograph), Symbol).new
    @made_of[[self]] = :create

    # puts "Created cograph with di-co-expression '#{@dicoexpr}'"
  end

  protected def initialize(@nodes, @edges, @dicoexpr, @made_of)
    # Removes parentheses around single node di-co-expressions, e.g. (v1) => v1
    @dicoexpr = @dicoexpr.gsub(/\((v\d+)\)/, "\\1", true)
    @predecessors = Hash(String, Array(String)).new
    @successors = Hash(String, Array(String)).new
    @nodes.keys.each do |node|
      @predecessors[node] = compute_predecessors(node)
      @successors[node] = compute_successors(node)
    end

    # puts "Created cograph with di-co-expression '#{@dicoexpr}'"
  end

  def sources
    @nodes.reject { |name, weight| @predecessors[name]? }
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

  # disjoint union
  def du(other : Cograph)
    check_unique_names(other)

    return Cograph.new(
      @nodes.merge(other.nodes),
      @edges + other.edges,
      "(#{@dicoexpr}) + (#{other.dicoexpr})",
      @made_of.merge(other.made_of).merge({[self, other] => :+})
    )
  end

  # series composition
  def sc(other : Cograph)
    check_unique_names(other)

    return Cograph.new(
      @nodes.merge(other.nodes),
      @edges + other.edges + Array.product(@nodes.keys, other.nodes.keys) + Array.product(other.nodes.keys, @nodes.keys),
      "(#{@dicoexpr}) x (#{other.dicoexpr})",
      @made_of.merge(other.made_of).merge({[self, other] => :x})
    )
  end

  # order composition
  def oc(other : Cograph)
    check_unique_names(other)

    return Cograph.new(
      @nodes.merge(other.nodes),
      @edges + other.edges + Array.product(@nodes.keys, other.nodes.keys),
      "(#{@dicoexpr}) / (#{other.dicoexpr})",
      @made_of.merge(other.made_of).merge({[self, other] => :/})
    )
  end

  private def check_unique_names(other : Cograph)
    @nodes.keys.each do |vertice|
      if other.nodes.keys.includes?(vertice)
        raise "Nodes not unique! #{vertice} appears at least twice in would be dicoexpr (#{@dicoexpr}) + (#{other.dicoexpr})."
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
