#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'uri'


 # * Key ontologies
 # * Foundational Model of Anatomy (FMA) - 44507
 # * Gene Ontology (GO) - 45968
 # * Gene Ontology Extension (GO) - 45890
 # * SNOMED Clinical Terms (SNOMEDCT) - 44777
 # * RadLex (RID) - 45589

class BioPortal
  attr_accessor :base_url, :apikey, :show_urls
  
  def initialize(params = nil)
    @show_urls = true
    if params
      if params[:base_url]
        @base_url = params[:base_url]
      else
        @base_url = "http://rest.bioontology.org/bioportal"
      end
      if params[:apikey]
        @apikey = params[:apikey]
      end
      if params[:show_urls]
        @show_urls = params[:show_urls]
      end
    end
  end
  
  def get_ontology(id)
    return Ontology.new(id, self)
  end
  
  def get_ontologies
    doc = get_page("ontologies")
    returnValue = []
    doc.xpath("success/data/list/ontologyBean").each do |ontology|
      o = Ontology.new
      o.bio_portal = self
      o.id = ontology.xpath("id").text
      o.ontology_id = ontology.xpath("ontologyId").text
      o.description = ontology.xpath("description").text
      o.label = ontology.xpath("displayLabel").text
      o.abbreviation = ontology.xpath("abbreviation").text
      returnValue.push(o)
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
        url += "&" + URI.escape("#{key}") + "=" + URI.escape("#{value}")
      end
    end
    if @show_urls 
      puts "getting url '#{url}'"
    end
    return Nokogiri::XML(open(url))
  end
  
end

class Ontology
  attr_accessor :id, :ontology_id, :description, :label, :abbreviation, :bio_portal
  
  def initialize(id, bio_portal)
    self.id = id
    self.bio_portal = bio_portal
    fill()
  end
  
  def fill
    doc = @bio_portal.get_page("ontologies/#{@id}")
    ontology = doc.xpath("success/data/ontologyBean")
    @ontology_id = ontology.xpath("ontologyId").text
    @description = ontology.xpath("description").text
    @label = ontology.xpath("displayLabel").text
    @abbreviation = ontology.xpath("abbreviation").text
  end
  
  def get_terms
    doc = bio_portal.get_page("concepts/#{@id}/root")
    return_value = []
    # get relation entry that has a string of "SubClass"
    sub_classes = doc.xpath("success/data/classBean/relations/entry").reject {|e| e.xpath('string').text !~ /SubClass/}.first
    if sub_classes
      sub_classes.xpath('list/classBean').each do |term|
        t = Term.new(:xml => term, :ontology => self)
        return_value.push(t)
      end
    end
    return return_value
  end
end

class Relation
  
end

class Term
  attr_accessor :id, :full_id, :label, :definition, :ontology, :child_count
  
  def initialize(params = nil)
    if params
      if params[:xml]
        xml = params[:xml]
        @id = xml.xpath("id").text
        @full_id = xml.xpath("fullId").text
        @label = xml.xpath("label").text
        @definition = xml.xpath("definitions/string").text
        @child_count = 0
        child_count = xml.xpath("relations/entry").reject {|e| e.xpath("string").text !~ /ChildCount/}.first
        if child_count
          @child_count = child_count.xpath("int").text.to_i
        end
      end
      if params[:ontology]
        @ontology = params[:ontology]
      end
    end
  end
  
  def get_children
    return_value = []
    doc = ontology.bio_portal.get_page("concepts/#{ontology.id}/#{id}", {:light => 1})
    sub_classes = doc.xpath("success/data/classBean/relations/entry").reject {|e| e.xpath('string').text !~ /SubClass/}.first
    if sub_classes
      sub_classes.xpath('list/classBean').each do |term|
        t = Term.new(:xml => term, :ontology => ontology)
        return_value.push(t)
      end
    end
    return return_value
  end
  
end

def main
  bp = BioPortal.new(:apikey => "6d3a093c-f01e-4003-b616-adcc5889a7fb", :base_url => "http://rest.bioontology.org/bioportal")
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



main