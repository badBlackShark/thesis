# This class implements a cograph that can be produced by the three operations
# disjoint union (+), series composition (x), and order composition (/). N^+ and N^- are computed
# automatically.
# This also computes 'made_of', which can be used to retrace the steps with which this cograph
# was built. This is really helpful later when computing solutions for SSG and SSGW.
class Cograph
  # The weights of the vertices
  getter nodes : Hash(String, Int32)
  getter edges : Array(Array(String))
  # The expression by which this cograph was built
  getter dicoexpr : String

  property sources : Hash(String, Int32)

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
    @sources = { name => weight }
    @made_of = Hash(Array(Cograph), Symbol).new
    @made_of[[self]] = :create

    # puts "Created cograph with di-co-expression '#{@dicoexpr}'"
  end

  protected def initialize(@nodes, @edges, @dicoexpr, @made_of)
    # Removes parentheses around single node di-co-expressions, e.g. (v1) => v1
    @dicoexpr = @dicoexpr.gsub(/\((v\d+)\)/, "\\1", true)
    @sources = compute_sources

    # puts "Created cograph with di-co-expression '#{@dicoexpr}'"
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
        graph.sources = graph.compute_sources
      end
    end

    @sources = compute_sources
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

  def compute_sources
    @nodes.reject { |name, weight| @edges.find { |edge| edge[1] == name } }
  end

  private def check_unique_names(other : Cograph)
    @nodes.keys.each do |vertice|
      if other.nodes.keys.includes?(vertice)
        raise "Nodes not unique! #{vertice} appears at least twice in would be di-co-expression (#{@dicoexpr}) + (#{other.dicoexpr})."
      end
    end
  end
end
