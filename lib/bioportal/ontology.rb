module Bioportal
  class Ontology
    attr_accessor :id, :ontology_id, :description, :label, :abbreviation, :bio_portal
    
    def initialize(id, bio_portal, fill = true)
      @id = id
      @bio_portal = bio_portal
      @filled = false
      if fill
        fillme
      end
    end
    
    def fillme
      @filled = true
      doc = @bio_portal.get_page("ontologies/#{@id}")
      if doc
        ontology = doc.xpath("success/data/ontologyBean")
        @ontology_id = ontology.xpath("ontologyId").text
        @description = ontology.xpath("description").text
        @label = ontology.xpath("displayLabel").text
        @abbreviation = ontology.xpath("abbreviation").text
      end
    end
    
    def exists?
      if !@filled
        fillme
      end
      if @label.nil?
        return false
      else
        return true
      end
    end
    
    def get_term(term_id)
      doc = bio_portal.get_page("concepts/#{@id}/#{term_id}")
      return Term.new(:xml => doc.xpath("success/data/classBean"), :ontology => self)
    end
    
    def get_terms
      doc = bio_portal.get_page("concepts/#{@id}/root")
      return_value = []
      # get relation entry that has a string of "SubClass"
      sub_classes = doc.xpath("success/data/classBean/relations/entry").reject {|e| e.xpath('string').text !~ /SubClass/}.first
      if sub_classes
        sub_classes.xpath('list/classBean').each do |term|
          t = Bioportal::Term.new(:xml => term, :ontology => self)
          return_value.push(t)
        end
      end
      return return_value
    end
  end
end