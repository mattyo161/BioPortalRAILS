#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'uri'

@apikey = "6d3a093c-f01e-4003-b616-adcc5889a7fb"
@base_url = "http://rest.bioontology.org/bioportal"
@desired_ontologies = [44507, 45890, 44777, 45589]

 # * Key ontologies
 # * Foundational Model of Anatomy (FMA) - 44507
 # * Gene Ontology Extension (GO) - 45890
 # * SNOMED Clinical Terms (SNOMEDCT) - 44777
 # * RadLex (RID) - 45589

class Ontology
  attr_accessor :id, :ontology_id, :description, :label, :abbreviation
end

class Concept
  attr_accessor :id, :full_id, :label, :definition, :ontology
  
  def get_children
    children = get_page("concepts/#{ontology.id}/#{id}", {:light => 1})
  end
end

def main
  puts "<html>
<head>
<style type=\"text/css\">
p {
  margin-top: 0;
}
.label {
  font-weight: bold;
  font-size: 120%;
}
li .id {
  font-family: monospace;
}
</style>
</head>
<body>
"
  groups = get_groups
  puts "<h1>Groups</h1>"
  puts "<ul>"
  groups.each {|x| puts "<li>#{x}</li>"}
  puts "</ul>"
  puts "<h1>Categories</h1>"
  puts "<ul>"
  get_categories.each {|x| puts "<li>#{x}</li>"}
  puts "</ul>"
  puts "<h1>Ontologies</h1>"
  puts "<ul>"
  os = get_ontologies
  os.sort {|a,b| a.abbreviation <=> b.abbreviation}.each do |o|
    if @desired_ontologies.include?(o.id.to_i)
      puts "<li><span class=\"label\">#{o.label}</span> (<span class=\"abbreviation\">#{o.abbreviation}</span>) - <span class=\"id\">#{o.id} = #{o.ontology_id}</span>"
      puts "<p>#{o.description}</p>"
      cs = get_concepts(o)
      puts "<ul>"
      cs.each do |c|
        puts "<li><span class=\"label\">#{c.label}</span> (<span class=\"id\">#{c.id}</span>) <a href=\"#{c.full_id}\">download</a>"
        puts "<p>#{c.definition}</p>"
        puts "</li>"
      end
      puts "</ul>"
      puts "</li>"
    end
  end
  puts "</ul>"
  puts "</body>
  </html>"
end

def get_ontologies
  doc = get_page("ontologies")
  returnValue = []
  doc.xpath("//ontologyBean").each do |ontology|
    o = Ontology.new
    o.id = ontology.xpath("id").text
    o.ontology_id = ontology.xpath("ontologyId").text
    o.description = ontology.xpath("description").text
    o.label = ontology.xpath("displayLabel").text
    o.abbreviation = ontology.xpath("abbreviation").text
    returnValue.push(o)
  end
  return returnValue
end

def get_concepts(ontology)
  doc = get_page("concepts/#{ontology.id}/root")
  returnValue = []
  doc.xpath("//relations/entry/list/classBean").each do |concept|
    c = Concept.new
    c.id = concept.xpath("id").text
    c.full_id = concept.xpath("fullId").text
    c.label = concept.xpath("label").text
    c.definition = concept.xpath("definitions/string").text
    c.ontology = ontology
    returnValue.push(c)
  end
  return returnValue
end

def get_categories
  return get_page("categories").xpath("//categoryBean").collect {|x| "#{x.xpath("name").text} (#{x.xpath("id").text})"}
end

def get_groups
  return get_page("groups").xpath("//groupBean").collect {|x| "#{x.xpath("name").text} (#{x.xpath("id").text})"}
end

def get_page(page, params=nil)
  url = "#{@base_url}/#{page}?apikey=#{@apikey}"
  if !params.nil?
    params.each do |key, value|
      url += "&#{URI.escape(key)}=#{URL.escape(value)}"
    end
  end
  puts "getting url '#{url}'"
  return Nokogiri::XML(open(url))
end

main