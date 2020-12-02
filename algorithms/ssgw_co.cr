class SSGW
  def self.solve_for_cograph(graph : Cograph, constraint : Int32)
    # This is used to find the index of certain di-co-expressions later in the program.
    # We do it here so we don't have to compute it a whole bunch of times.
    searchable = graph.made_of.map do |g, op|
      if op == :create
        g[0].dicoexpr
      else
        # The gsub gets rid of parentheses around single vertices. This way the di-co-expression
        # looks like the di-co-expression of the actual graph
        "(#{g[0].dicoexpr}) #{op} (#{g[1].dicoexpr})".gsub(/\((v\d+)\)/, "\\1")
      end
    end

    h_prime, h_prime_solutions = compute_h_prime(graph, constraint, searchable)
    h, sol_sets = compute_h_and_solution_sets(graph, constraint, searchable, h_prime, h_prime_solutions)

    # This is only for debugging and checking the very large table for examples
    # 0.upto(constraint) do |s_prime|
    #   puts "\ns'=#{s_prime}"
    #   0.upto(graph.made_of.keys.size - 1) do |i|
    #     key = graph.made_of.keys[i]
    #     print "#{key[0].dicoexpr} #{graph.made_of[key]} #{key[1]?.try(&.dicoexpr)}: "
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

  private def self.compute_h_prime(graph : Cograph, c : Int32, searchable : Array(String))
    h_prime = Array(Array(Bool)).new
    sol_sets = Array(Array(Array(String)?)).new

    0.upto(graph.made_of.keys.size - 1) do |i|
      h_prime << Array(Bool).new(c + 1, false)
      sol_sets << Array(Array(String)?).new(c + 1, nil)
    end

    graph.made_of.each_with_index do |(step, operator), i|
      0.upto(c) do |s|
        case operator
        when :create
          if s == 0
            h_prime[i][s] = true
            sol_sets[i][s] = Array(String).new
          elsif s == step.first.nodes.first[1]
            h_prime[i][s] = true
            sol_sets[i][s] = step.first.nodes.keys
          end
        else
          # If either of those two lines throws an error something went horribly wrong in building the cograph.
          left_i = searchable.index(step[0].dicoexpr).not_nil!
          right_i = searchable.index(step[1].dicoexpr).not_nil!

          0.upto(s) do |s_prime|
            0.upto(s) do |s_double_prime|
              if s_prime + s_double_prime == s && h_prime[left_i][s_prime] && h_prime[right_i][s_double_prime]
                h_prime[i][s] = true
                sol_sets[i][s] = sol_sets[left_i][s_prime].not_nil! + sol_sets[right_i][s_double_prime].not_nil!
              end
            end
          end
        end
      end
    end

    return h_prime, sol_sets
  end

  private def self.compute_h_and_solution_sets(graph : Cograph, c : Int32, searchable : Array(String), h_prime : Array(Array(Bool)), h_prime_solutions : Array(Array(Array(String)?)))
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
          when :+
            # If either of those two lines throws an error something went horribly wrong in building the cograph.
            left_i = searchable.index(step[0].dicoexpr).not_nil!
            right_i = searchable.index(step[1].dicoexpr).not_nil!

            0.upto(s) do |s_1|
              0.upto(s) do |s_2|
                0.upto(s_prime) do |s_1_prime|
                  0.upto(s_prime) do |s_2_prime|
                    if (
                         s_1 + s_2 == s &&
                         s_1_prime + s_2_prime == s_prime &&
                         h[left_i][s_1][s_1_prime] &&
                         h[right_i][s_2][s_2_prime]
                       )
                      h[i][s][s_prime] = true
                      sol_sets[i][s][s_prime] = sol_sets[left_i][s_1][s_1_prime].not_nil! + sol_sets[right_i][s_2][s_2_prime].not_nil!
                    end
                  end
                end
              end
            end
          when :/
            # If either of those two lines throws an error something went horribly wrong in building the cograph.
            left_i = searchable.index(step[0].dicoexpr).not_nil!
            right_i = searchable.index(step[1].dicoexpr).not_nil!

            s_x1 = step[0].nodes.values.sum
            s_x2 = step[1].nodes.values.sum

            # We're going through the 5 options presented in lemma 3.14 one by one here and quitting
            # as soon as we find one that fits.
            # Option 1:
            if s >= 1 && s < s_x1 && h[left_i][s][s_prime]
              h[i][s][s_prime] = true
              sol_sets[i][s][s_prime] = sol_sets[left_i][s][s_prime]
              next
            end

            # Option 2
            if s_prime == 0 && s <= s_x2 && h_prime[right_i][s]
              h[i][s][s_prime] = true
              sol_sets[i][s][s_prime] = h_prime_solutions[right_i][s]
              next
            end

            # Option 3
            1.upto(s_x2) do |s_2|
              if s_x1 + s_2 == s && step[0].sources.values.sum == s_prime && h[right_i][s_2][step[1].sources.values.sum]
                h[i][s][s_prime] = true
                sol_sets[i][s][s_prime] = step[0].nodes.keys + sol_sets[right_i][s_2][step[1].sources.values.sum].not_nil!
              end
            end
            next if h[i][s][s_prime]

            # Option 4
            if s_x1 + s_x2 == s && step[0].sources.values.sum == s_prime
              h[i][s][s_prime] = true
              sol_sets[i][s][s_prime] = step[0].nodes.keys + step[1].nodes.keys
              next
            end

            # Option 5
            0.upto(s_x1 - 1) do |s_1|
              0.upto(s_x2) do |s_2|
                if s_1 + s_2 == s && h[left_i][s_1][s_prime] && h_prime[right_i][s_2]
                  h[i][s][s_prime] = true
                  sol_sets[i][s][s_prime] = sol_sets[left_i][s_1][s_prime].not_nil! + h_prime_solutions[right_i][s_2].not_nil!
                end
              end
            end
          when :x
            next unless s_prime == 0

            # If either of those two lines throws an error something went horribly wrong in building the cograph.
            left_i = searchable.index(step[0].dicoexpr).not_nil!
            right_i = searchable.index(step[1].dicoexpr).not_nil!

            s_x1 = step[0].nodes.values.sum
            s_x2 = step[1].nodes.values.sum

            # We're going through the 6 options presented in lemma 3.14 one by one here and quitting
            # as soon as we find one that fits.
            # Option 1
            if s >= 1 && s < s_x1 && h_prime[left_i][s]
              h[i][s][0] = true
              sol_sets[i][s][0] = h_prime_solutions[left_i][s]
              next
            end

            # Option 2
            if s < s_x2 && h_prime[right_i][s]
              h[i][s][0] = true
              sol_sets[i][s][0] = h_prime_solutions[right_i][s]
              next
            end

            # Option 3
            1.upto(s_x2) do |s_2|
              if s_x1 + s_2 == s && h[right_i][s_2][step[1].sources.values.sum]
                h[i][s][0] = true
                sol_sets[i][s][0] = step[0].nodes.keys + sol_sets[right_i][s_2][step[1].sources.values.sum].not_nil!
              end
            end
            next if h[i][s][0]

            # Option 4
            1.upto(s_x1) do |s_1|
              if s_1 + s_x2 == s && h[left_i][s_1][step[0].sources.values.sum]
                h[i][s][0] = true
                sol_sets[i][s][0] = sol_sets[left_i][s_1][step[0].sources.values.sum].not_nil! + step[1].nodes.keys
              end
            end
            next if h[i][s][0]

            # Option 5
            if s_x1 + s_x2 == s
              h[i][s][0] = true
              sol_sets[i][s][0] = step[0].nodes.keys + step[1].nodes.keys
              next
            end

            # Option 6
            1.upto(s_x1 - 1) do |s_1|
              1.upto(s_x2 - 1) do |s_2|
                if s_1 + s_2 == s && h_prime[left_i][s_1] && h_prime[right_i][s_2]
                  h[i][s][0] = true
                  sol_sets[i][s][0] = h_prime_solutions[left_i][s_1].not_nil! + h_prime_solutions[right_i][s_2].not_nil!
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
