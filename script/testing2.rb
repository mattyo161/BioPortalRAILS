$LOAD_PATH << File.expand_path('../lib')

require 'bioportal'

bp = Bioportal(:apikey => "6d3a093c-f01e-4003-b616-adcc5889a7fb", :base_url => "http://rest.bioontology.org/bioportal")
bp.show_urls = false
@desired_ontologies = [44507, 45890, 44777, 45589]
o = bp.get_ontology(45968)
puts "#{o.label} - #{o.ontology_id} (#{o.id})"
puts o.description

terms = o.get_terms
puts "Found #{terms.length} terms"
terms.sort {|a,b| a.label <=> b.label}.each do |term|
  puts "#{term.label} (#{term.id}) - #{term.definition}"
  children = term.get_children
  children.sort {|a,b| a.label <=> b.label}.each do |child|
    puts "\t#{child.label} (#{child.child_count})"
    if child.child_count > 0
      children2 = child.get_children
      children2.sort {|a,b| a.label <=> b.label}.each do |child2|
        puts "\t\t#{child2.label} (#{child2.child_count})"
      end
    end
  end
end
