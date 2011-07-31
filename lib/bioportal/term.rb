module Bioportal
  class Term
    attr_accessor :id, :full_id, :label, :definition, :ontology, :child_count, 
          :relations, :type, :comment, :subset, :xref, :is_a, :r_is_a, :super_class, 
          :alt_id, :disjoint_from, :r_disjoint_from, :part_of,
          :synonyms, :regulates
          
    def initialize(params = nil)
      if params
        if params[:ontology]
          @ontology = params[:ontology]
        end
        if params[:xml]
          xml = params[:xml]
          @id = xml.xpath("id").text
          @full_id = xml.xpath("fullId").text
          @label = xml.xpath("label").text
          @definition = xml.xpath("definitions/string").text
          @child_count = 0
          @relations = {}
          @is_a = []
          @r_is_a = []
          @disjoint_from = []
          @r_disjoint_from = []
          @super_class = []
          @part_of = []
          @subset = []
          @synonyms = {}
          @regulates = {}
          xml.xpath("relations/entry").each do |entry|
            type = entry.xpath("string").text
            if type =~ /ChildCount/
              @child_count = entry.xpath("int").text.to_i
            elsif type =~ /comment/i
              @comment = entry.xpath("list/string").collect {|x| x.text}
            elsif type =~ /broad synonym/i
              @synonyms['broad'] = entry.xpath("list/string").collect {|x| x.text}
            elsif type =~ /exact synonym/i
              @synonyms['exact'] = entry.xpath("list/string").collect {|x| x.text}
            elsif type =~ /narrow synonym/i
              @synonyms['narrow'] = entry.xpath("list/string").collect {|x| x.text}
            elsif type =~ /related synonym/i
              @synonyms['related'] = entry.xpath("list/string").collect {|x| x.text}
            elsif type =~ /subset/i
              @subset = entry.xpath("list/string").collect {|x| x.text}
            elsif type =~ /xref/i
              @xref = entry.xpath("list/string").text
            elsif type =~ /alt_id/i
              @alt_id = entry.xpath("list/string").text
            elsif type =~ /part_of/i
              entry.xpath("list/classBean").each do |entry|
                term = Term.new(:xml => entry, :ontology => @ontology)
                @part_of.push(term)
              end
            elsif type =~ /\[R\]is_a/i
              entry.xpath("list/classBean").each do |entry|
                term = Term.new(:xml => entry, :ontology => @ontology)
                @r_is_a.push(term)
              end
            elsif type =~ /is_a/i
              entry.xpath("list/classBean").each do |entry|
                term = Term.new(:xml => entry, :ontology => @ontology)
                @is_a.push(term)
              end
            elsif type =~ /^\[R\]regulates/i
              @regulates["r_"] = []
              entry.xpath("list/classBean").each do |entry|
                term = Term.new(:xml => entry, :ontology => @ontology)
                @regulates["r_"].push(term)
              end
            elsif type =~ /\[R\]positively_regulates/i
              @regulates["r_positively"] = []
              entry.xpath("list/classBean").each do |entry|
                term = Term.new(:xml => entry, :ontology => @ontology)
                @regulates["r_positively"].push(term)
              end
            elsif type =~ /\[R\]negatively_regulates/i
              @regulates["r_negatively"] = []
              entry.xpath("list/classBean").each do |entry|
                term = Term.new(:xml => entry, :ontology => @ontology)
                @regulates["r_negatively"].push(term)
              end
            elsif type =~ /^regulates/i
              @regulates["just"] = []
              entry.xpath("list/classBean").each do |entry|
                term = Term.new(:xml => entry, :ontology => @ontology)
                @regulates["just"].push(term)
              end
            elsif type =~ /^positively_regulates/i
              @regulates["positively"] = []
              entry.xpath("list/classBean").each do |entry|
                term = Term.new(:xml => entry, :ontology => @ontology)
                @regulates["positively"].push(term)
              end
            elsif type =~ /^negatively_regulates/i
              @regulates["negatively"] = []
              entry.xpath("list/classBean").each do |entry|
                term = Term.new(:xml => entry, :ontology => @ontology)
                @regulates["negatively"].push(term)
              end
            elsif type =~ /\[R\]disjoint_from/i
              entry.xpath("list/classBean").each do |entry|
                term = Term.new(:xml => entry, :ontology => @ontology)
                @r_disjoint_from.push(term)
              end
            elsif type =~ /disjoint_from/i
              entry.xpath("list/classBean").each do |entry|
                term = Term.new(:xml => entry, :ontology => @ontology)
                @disjoint_from.push(term)
              end
            elsif type =~ /SuperClass/i
              entry.xpath("list/classBean").each do |entry|
                term = Term.new(:xml => entry, :ontology => @ontology)
                @super_class.push(term)
              end
            else
              @relations[type] = entry
            end
          end
        end
      end
    end
    
    def xml_url
      ontology.bio_portal.get_page_url("concepts/#{ontology.id}/#{id}")
    end
    
    def get_children
      return_value = []
      doc = ontology.bio_portal.get_page("concepts/#{ontology.id}/#{id}", {:light => 1})
      sub_classes = doc.xpath("success/data/classBean/relations/entry").reject {|e| e.xpath('string').text !~ /SubClass/}.first
      if sub_classes
        sub_classes.xpath('list/classBean').each do |term|
          t = Bioportal::Term.new(:xml => term, :ontology => ontology)
          return_value.push(t)
        end
      end
      return return_value
    end
    
  end
end