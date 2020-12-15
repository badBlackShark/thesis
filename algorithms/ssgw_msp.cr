class SSGW
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

    h, sol_sets = compute_h_and_solution_sets(graph, constraint, searchable)

    # This is only for debugging and checking the very large table for examples
    # 0.upto(constraint) do |s_prime|
    #   puts "\ns'=#{s_prime}"
    #   0.upto(graph.made_of.keys.size - 1) do |i|
    #     key = graph.made_of.keys[i]
    #     print "#{key[0].mspexpr} #{graph.made_of[key]} #{key[1]?.try(&.mspexpr)}: "
    #     0.upto(constraint) do |s|
    #       print "#{h[i][s][s_prime] ? 1 : 0} "
    #     end
    #     puts ""
    #   end
    # end

    constraint.downto(0) do |i|
      0.upto(constraint) do |j|
        if h[-1][i][j]
          return i, sol_sets[-1][i][j]
        end
      end
    end

    # This should never be reached, because the empty solution is always viable.
    # Sometimes you just have to appease the almighty type checker.
    return -1, ["A fatal error occurred. Problem couldn't be solved."]
  end

  private def self.compute_h_and_solution_sets(graph : Mspgraph, c : Int32, searchable : Array(String))
    h = Array(Array(Array(Bool))).new
    # Solution sets; contains the vertices chosen for any given possible solution.
    # nil indicates an unsolvable problem; [] indicates an empty solution.
    sol_sets = Array(Array(Array(Array(String)?))).new
    0.upto(graph.made_of.keys.size - 1) do |i|
      h << Array(Array(Bool)).new
      sol_sets << Array(Array(Array(String)?)).new

      0.upto(c) do |j|
        h[i] << Array(Bool).new(c + 1, false)
        sol_sets[i] << Array(Array(String)?).new(c + 1, nil)
      end
    end

    graph.made_of.each_with_index do |(step, operator), i|
      0.upto(c) do |s|
        0.upto(c) do |s_prime|
          case operator
          when :create
            next unless s == s_prime
            if s == 0
              h[i][s][s_prime] = true
              sol_sets[i][s][s_prime] = Array(String).new
            elsif s == step.first.nodes.first[1]
              h[i][s][s_prime] = true
              sol_sets[i][s][s_prime] = step.first.nodes.keys
            end
          when :u
            # If either of those two lines throws an error something went horribly wrong in building the Mspgraph.
            left_i = searchable.index(step[0].mspexpr).not_nil!
            right_i = searchable.index(step[1].mspexpr).not_nil!

            0.upto(s // 2) do |n|
              s_1 = n
              s_2 = s - n
              0.upto(s_prime // 2) do |m|
                s_1_prime = m
                s_2_prime = s_prime - m
                if (h[left_i][s_1][s_1_prime] && h[right_i][s_2][s_2_prime])
                  h[i][s][s_prime] = true
                  sol_sets[i][s][s_prime] = sol_sets[left_i][s_1][s_1_prime].not_nil! + sol_sets[right_i][s_2][s_2_prime].not_nil!
                  break
                elsif (h[right_i][s_1][s_1_prime] && h[left_i][s_2][s_2_prime])
                  h[i][s][s_prime] = true
                  sol_sets[i][s][s_prime] = sol_sets[right_i][s_1][s_1_prime].not_nil! + sol_sets[left_i][s_2][s_2_prime].not_nil!
                  break
                end
              end
            end
          when :x
            # If either of those two lines throws an error something went horribly wrong in building the Mspgraph.
            left_i = searchable.index(step[0].mspexpr).not_nil!
            right_i = searchable.index(step[1].mspexpr).not_nil!

            s_x1 = step[0].nodes.values.sum
            s_x2 = step[1].nodes.values.sum

            # We're going through the four options presented in lemma 4.18 one by one here and quitting
            # as soon as we find one that fits.
            # Option 1:
            if h[right_i][s][s_prime]
              h[i][s][s_prime] = true
              sol_sets[i][s][s_prime] = sol_sets[right_i][s][s_prime]
              next
            end

            # Option 2
            if s_prime == 0
              # The min is necessary since we get an index that's out of bounds if the sum of sinks
              # is larger than the constraint itself
              1.upto(Math.min(step[0].sinks.values.sum - 1, c)) do |s_1_prime|
                if s != 0 && h[left_i][s][s_1_prime]
                  h[i][s][s_prime] = true
                  sol_sets[i][s][s_prime] = sol_sets[left_i][s][s_1_prime]
                  break
                end
              end
            end
            next if h[i][s][s_prime]

            # Option 3
            1.upto(s_x1) do |s_1|
              # As above, we need to make sure we don't go out of bounds with the sum of sinks
              if s_1 + s_x2 == s && step[1].sinks.values.sum == s_prime && step[0].sinks.values.sum <= c && h[left_i][s_1][step[0].sinks.values.sum]
                h[i][s][s_prime] = true
                sol_sets[i][s][s_prime] = sol_sets[left_i][s_1][step[0].sinks.values.sum].not_nil! + sol_sets[right_i][s_x2][step[1].sinks.values.sum].not_nil!
                break
              end
            end
            next if h[i][s][s_prime]

            # Option 4
            # Better for small weights
            # 1.upto(s_x1) do |s_1|
            #   1.upto(s_x2) do |s_2|
            #     1.upto(Math.min(step[0].sinks.values.sum - 1, c)) do |s_1_prime|
            #       1.upto(s_x2) do |s_2_prime|
            #         if s_1 + s_2 == s && s_2_prime == s_prime && h[left_i][s_1][s_1_prime] && h[right_i][s_2][s_2_prime]
            #           h[i][s][s_prime] = true
            #           sol_sets[i][s][s_prime] = sol_sets[left_i][s_1][s_1_prime].not_nil! + sol_sets[right_i][s_2][s_2_prime].not_nil!
            #         end
            #       end
            #     end
            #   end
            # end

            # Better for large weights
            1.upto(s // 2) do |n|
              # break if n > s_x1 + s_x2 # Is only worth if the weights are much smaller than the constraint I think
              s_1 = n
              s_2 = s - n
              1.upto(Math.min(step[0].sinks.values.sum - 1, c)) do |s_1_prime|
                if h[left_i][s_1][s_1_prime] && h[right_i][s_2][s_prime]
                  h[i][s][s_prime] = true
                  sol_sets[i][s][s_prime] = sol_sets[left_i][s_1][s_1_prime].not_nil! + sol_sets[right_i][s_2][s_prime].not_nil!
                  break
                elsif h[right_i][s_1][s_1_prime] && h[left_i][s_2][s_prime]
                  h[i][s][s_prime] = true
                  sol_sets[i][s][s_prime] = sol_sets[right_i][s_1][s_1_prime].not_nil! + sol_sets[left_i][s_2][s_prime].not_nil!
                  break
                end
              end
            end
          end
        end
      end
    end

    return h, sol_sets
  end
end
