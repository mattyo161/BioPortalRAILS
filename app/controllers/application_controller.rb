require 'bioportal'

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_bioportal
  
  def set_bioportal
    if @bioportal.nil?
      # live configuration
      # @bioportal = Bioportal(:apikey => "6d3a093c-f01e-4003-b616-adcc5889a7fb", :base_url => "http://rest.bioontology.org/bioportal")
      # test configuration
      @bioportal = Bioportal(:apikey => "56aa99e3-07d4-4f5c-a673-02258e5c02af", :base_url => "http://stagerest.bioontology.org/bioportal")
      @bioportal.show_urls = true
    end
  end
end
