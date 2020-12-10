require "./graphs/*"
require "./algorithms/*"
require "./parser/*"
require "option_parser"

expression = ""
weights = Array(Int32).new
constraint = 0
problem = ""
graph_type = ""

OptionParser.parse do |parser|
  parser.banner = "Usage: solver [arguments]"
  parser.on("-g GRAPHTYPE", "--graph GRAPHTYPE", "Sets whether to solve for a directed Co- or MSP-Graph. Must be \"co“ or \"msp\".") do |graph|
    graph = graph.downcase
    raise "Graph type must be either \"co\" or \"msp\"" unless graph == "co" || graph == "msp"
    graph_type = graph
  end
  parser.on("-e EXPRESSION", "--expr EXPRESSION", "Inputs a graph as an expression. Must be fully parenthesized.") { |expr| expression = expr }
  parser.on("-w WEIGHTS", "--weights WEIGHTS", "Specifies the weights for the given graph. \
            Number of weights must match the number of nodes in the graph. \
            All weights must be given as one argument in quotes, and must be separated by spaces.\n\
            E.g.: -w \"1 2 2 3\"") { |raw| weights = raw.split(" ").map(&.to_i) }
  parser.on("-c CONSTRAINT", "--constraint CONSTRAINT", "Specifies the weight constraint for the problem.") { |constr| constraint = constr.to_i }
  parser.on("-p PROBLEM", "--problem PROBLEM", "Specifies whether SSG or SSGW should be solved. Must be one of those two.") do |probl|
    probl = probl.upcase
    raise "Problem must be either \"SSG\" or \"SSGW\"." unless probl == "SSG" || probl == "SSGW"
    problem = probl
  end
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option. Use -h to see all valid options."
    STDERR.puts parser
    exit(1)
  end
end

start = Time.monotonic
case graph_type
when "co"
  graph = Dicoparser::Pegasus::Generated.process(expression).as(Cograph)
  graph.add_weights(weights)

  File.open("./times_ssg_co.txt", "a") do |file|
    # 0.upto(200) do |c|
    #   constraint = c*50
      start_it = Time.monotonic
      size, sol = if problem == "SSG"
                    SSG.solve_for_cograph(graph, constraint)
                  else
                    SSGW.solve_for_cograph(graph, constraint)
                  end
      puts "The optimal #{problem} solution for the given cograph with di-co-expression \"#{expression}\" and constraint #{constraint} is #{sol} with size #{size}."
      finish = Time.monotonic - start_it
    #   txt = "Solved for c=#{constraint} in #{finish}"
    #   puts txt
    #   file.puts(txt)
    # end
  end
when "msp"
  graph = Mspparser::Pegasus::Generated.process(expression).as(Mspgraph)
  graph.add_weights(weights)

  size, sol = if problem == "SSG"
                SSG.solve_for_mspgraph(graph, constraint)
              else
                SSGW.solve_for_mspgraph(graph, constraint)
              end
  puts "The optimal #{problem} solution for the given msp-graph with msp-expression \"#{expression}\" and constraint #{constraint} is #{sol} with size #{size}."
else
  puts "Graph type not specified!"
  exit 1
end
puts "Combined time needed to compute: #{Time.monotonic - start}"
