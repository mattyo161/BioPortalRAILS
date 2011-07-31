require 'bioportal'

class BioportalsController < ApplicationController
  def show
    desired_ontologies = [46085, 45968, 45890, 44507, 44777, 45589]
    @ontologies = []
    desired_ontologies.each do |id|
      ontology = @bioportal.get_ontology(id)
      if ontology.exists?
        @ontologies.push(ontology)
      end
    end
    all_ontologies = @bioportal.get_ontologies
    all_ontologies.sort {|a,b| a.label <=> b.label}.each do |o|
      if !desired_ontologies.include?(o.id)
        @ontologies.push(o)
      end
    end
  end
  
  def get_ontology
    if params[:oid]
      @ontology = @bioportal.get_ontology(params[:oid])
      @terms = @ontology.get_terms
    end
    render :partial => "get_ontology"
  end
  
  def get_terms
    if params[:oid] and params[:tid]
      @ontology = @bioportal.get_ontology(params[:oid])
      @term = @ontology.get_term(params[:tid])
      @terms = @term.get_children
    end
    render :partial => "get_terms"
  end
  
  def get_term_details
    if params[:oid] and params[:tid]
      @ontology = @bioportal.get_ontology(params[:oid])
      @term = @ontology.get_term(params[:tid])
    end
    render :partial => "get_term_details"
  end
  
  def use_staging_server
    @bioportal.base_url = "http://stagerest.bioontology.org/bioportal"
    redirect_to "/bioportal"
  end
end
