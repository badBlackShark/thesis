require "./graphs/*"

v1 = Cograph.new("v1", 1)
v2 = Cograph.new("v2", 2)
v3 = Cograph.new("v3", 1)
v4 = Cograph.new("v4", 5)
v5 = Cograph.new("v5", 2)

c1 = v1.oc(v2)
puts "----------------------"
c2 = v3.du(c1)
puts "----------------------"
c3 = v4.du(v5)
puts "----------------------"
c4 = c2.oc(c3)
puts "----------------------"
c4.made_of.each do |k, v|
  print "#{k.map { |e| e.dicoexpr }}, "
  puts v
end
