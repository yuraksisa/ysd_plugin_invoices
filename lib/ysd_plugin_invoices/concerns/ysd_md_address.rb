require 'data_mapper' unless defined?DataMapper::Resource

module Yito
  module Concern
    module Invoices
	  #
	  # Represent an address
	  #
	  module Address

	    def self.included(model)

          if model.respond_to?(:property)  
	        model.property :address_line_1, String, :length => 100
	        model.property :address_line_2, String, :length => 100
	        model.property :address_city, String, :length => 60
	        model.property :address_state, String, :length => 60
	        model.property :address_country, String, :length => 50
	        model.property :address_zip, String, :length => 10
	      end  

	    end

	  end
	end
  end
end  	
	    	