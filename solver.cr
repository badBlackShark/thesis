require "./graphs/*"
require "./algorithms/*"
require "./parser/*"
require "option_parser"

dicoexpr = ""
weights = Array(Int32).new
constraint = 0
problem = ""

OptionParser.parse do |parser|
  parser.banner = "Usage: solver [arguments]"
  parser.on("-d EXPRESSION", "--dicoexpr=EXPRESSION", "Inputs a directed co-graph as a di-co-expression. Must be fully parenthesized.") { |expr| dicoexpr = expr }
  parser.on("-w WEIGHTS", "--weights=WEIGHTS", "Specifies the weights for the given graph. \
            Number of weights must match the number of nodes in the graph. \
            All weights must be given as one argument in quotes, and must be separated by spaces.\n\
            E.g.: -w \"1 2 2 3\"") { |raw| weights = raw.split(" ").map(&.to_i) }
  parser.on("-c CONSTRAINT", "--constraint=CONSTRAINT", "Specifies the weight constraint for the problem.") { |constr| constraint = constr.to_i }
  parser.on("-p PROBLEM", "--problem=PROBLEM", "Specifies whether SSG or SSGW should be solved. Must be one of those two.") do |probl|
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

graph = Dicoparser::Pegasus::Generated.process(dicoexpr).as(Cograph)
graph.add_weights(weights)

size, sol = if problem == "SSG"
  SSG.solve_for_cograph(graph, constraint)
else
  SSGW.solve_for_cograph(graph, constraint)
end
puts "The optimal #{problem} solution for the given cograph with di-co-expression \"#{dicoexpr}\" and constraint #{constraint} is #{sol} with size #{size}."
