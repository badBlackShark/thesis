class SSG
  # Solves SSG for a given graph and constraint.
  # Returns the best value achievable, and the elements chosen to achieve that value.
  def self.solve_for_mspgraph(graph : Mspgraph, constraint : Int32)
    # This is used to find the index of certain msp-expressions later in the program.
    # We do it here so we don't have to compute it a whole bunch of times.
    searchable = graph.made_of.map do |g, op|
      if op == :create
        g[0].mspexpr
      else
        # The gsub gets rid of parentheses around single vertices. This way the msp-expression
        # looks like the msp-expression of the actual graph
        "(#{g[0].mspexpr}) #{op} (#{g[1].mspexpr})".gsub(/\((v\d+)\)/, "\\1")
      end
    end

    f, sol_sets = compute_f_and_solution_sets(graph, constraint, searchable)

    best_s = constraint.downto(0) do |i|
      if f[-1][i]
        break i
      end
    end.not_nil! # This will never trigger, because the empty solution is always viable.
    # Sometimes you just have to appease the almighty type checker.

    return best_s, sol_sets[-1][best_s]
  end

  # Computes the F function (as lined out in GKR20) for a given graph and constraint c.
  # Also computes which elements need to be chosen to achieve the result of every field
  # in the matrix F.
  # As lined out above, the `searchable` is only there to save some instructions.
  private def self.compute_f_and_solution_sets(graph : Mspgraph, c : Int32, searchable : Array(String))
    f = Array(Array(Bool)).new
    # Solution sets; contains the vertices chosen for any given possible solution.
    # nil indicates an unsolvable problem; [] indicates an empty solution.
    sol_sets = Array(Array(Array(String)?)).new

    0.upto(graph.made_of.keys.size - 1) do |i|
      f << Array(Bool).new(c + 1, false)
      sol_sets << Array(Array(String)?).new(c + 1, nil)
    end

    graph.made_of.each_with_index do |(step, operator), i|
      0.upto(c) do |s|
        case operator
        when :create
          if s == 0
            f[i][s] = true
            sol_sets[i][s] = Array(String).new
          elsif s == step.first.nodes.first[1]
            f[i][s] = true
            sol_sets[i][s] = step.first.nodes.keys
          end
        when :u
          # If either of those two lines throws an error something went horribly wrong in building the msp-graph.
          left_i = searchable.index(step[0].mspexpr).not_nil!
          right_i = searchable.index(step[1].mspexpr).not_nil!

          0.upto(s) do |s_prime|
            0.upto(s) do |s_double_prime|
              if s_prime + s_double_prime == s && f[left_i][s_prime] && f[right_i][s_double_prime]
                f[i][s] = true
                sol_sets[i][s] = sol_sets[left_i][s_prime].not_nil! + sol_sets[right_i][s_double_prime].not_nil!
              end
            end
          end
        when :x
          # If either of those two lines throws an error something went horribly wrong in building the msp-graph.
          left_i = searchable.index(step[0].mspexpr).not_nil!
          right_i = searchable.index(step[1].mspexpr).not_nil!

          if f[right_i][s]
            f[i][s] = true
            sol_sets[i][s] = sol_sets[right_i][s]
          else
            f_x2 = step[1].nodes.values.sum
            1.upto(s) do |s_prime|
              if s_prime + f_x2 == s && f[left_i][s_prime]
                f[i][s] = true
                sol_sets[i][s] = sol_sets[left_i][s_prime].not_nil! + sol_sets[right_i][f_x2].not_nil!
              end
            end
          end
        end
      end
    end

    return f, sol_sets
  end
end
