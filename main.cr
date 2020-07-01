require "./graphs/*"
require "./algorithms/*"

# A cograph with one node can be built using Cograph.new(name of node, weight of node). Those nodes
# can then be combined using the disjoint union (du), series composition (sc), or order composition (oc)
# operations, which return the resulting cograph without modifying the existing ones.
# Enter your graph here:

v1 = Cograph.new("v1", 2)
v2 = Cograph.new("v2", 2)
v3 = Cograph.new("v3", 2)
v4 = Cograph.new("v4", 3)

c1 = v1.du(v3)
c2 = v2.sc(v4)
c3 = c1.oc(c2)

# Now enter your constraint:
constraint = 7

# Just for testing purposes
# puts ""
# c3.made_of.each do |k, v|
#   print "#{k.map { |e| e.dicoexpr }}, "
#   puts v
# end

puts "\nFinished building cograph. Computing F now.\n"

size, sol = SSG.solve_for_cograph(c3, constraint)
puts "The optimal SSG solution for the given cograph and constraint is #{sol} with size #{size}."
