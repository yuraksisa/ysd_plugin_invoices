require 'data_mapper' unless defined?DataMapper::Resource

module Yito
  module Concern
    module Invoices
	  #
	  # Represent totals
	  #
	  module ItemTotals

	    def self.included(model)

          if model.respond_to?(:property) 
	        model.property :quantity, Integer
	        model.property :vat_type, String, length: 10
	        model.property :vat_percentage, DataMapper::Property::Decimal, precision: 10, scale: 2
	        model.property :price_without_taxes, DataMapper::Property::Decimal, precision: 10, scale: 2
	        model.property :unit_taxes, DataMapper::Property::Decimal, precision: 10, scale: 2
	        model.property :total_without_taxes, DataMapper::Property::Decimal, precision: 10, scale: 2
	        model.property :taxes, DataMapper::Property::Decimal, precision: 10, scale: 2
	        model.property :total, DataMapper::Property::Decimal, precision: 10, scale: 2
          end
 
	    end

	  end
	end
  end
end  	
	    	