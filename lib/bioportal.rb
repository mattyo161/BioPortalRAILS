require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'bioportal/ontology'
require 'bioportal/term'

module Bioportal
  class Server
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
      return Bioportal::Ontology.new(id, self)
    end
    
    def get_ontologies
      doc = get_page("ontologies")
      returnValue = []
      doc.xpath("success/data/list/ontologyBean").each do |ontology|
        o = Bioportal::Ontology.new(ontology.xpath("id").text, self, false)
        # o.bio_portal = self
        # o.id = ontology.xpath("id").text
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
      url = get_page_url(page, params)
      if @show_urls 
        puts "getting url '#{url}'"
      end
      begin
        return Nokogiri::XML(open(url))
      rescue Exception => e
        puts "Encountered error '#{e}' retrieving page '#{url}'"
        puts e.backtrace
        return nil
      end
    end
    
    def get_page_url(page, params=nil)
      url = "#{@base_url}/#{page}?apikey=#{@apikey}"
      if !params.nil?
        params.each do |key, value|
          url += "&" + URI.escape("#{key}") + "=" + URI.escape("#{value}")
        end
      end
      return url
    end
  end
end

def Bioportal(*args)
  Bioportal::Server.new(*args)
end
