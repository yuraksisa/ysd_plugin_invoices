require 'data_mapper' unless defined?DataMapper::Resource

module Yito
  module Concern
    module Invoices
	  #
	  # Represent totals
	  #
	  module Totals

	    def self.included(model)

           if model.respond_to?(:property)
	           model.property :total_without_taxes_standard, DataMapper::Property::Decimal, precision: 10, scale: 2
	           model.property :total_without_taxes_reduced, DataMapper::Property::Decimal, precision: 10, scale: 2
	           model.property :total_without_taxes_reduced_2, DataMapper::Property::Decimal, precision: 10, scale: 2
	           model.property :total_without_taxes_reduced_3, DataMapper::Property::Decimal, precision: 10, scale: 2
             model.property :discount_type, DataMapper::Property::Enum[:percent, :amount]
  		       model.property :discount, DataMapper::Property::Decimal, precision: 10, scale: 2
  		       model.property :disount_tp, DataMapper::Property::Decimal, precision: 10, scale: 2

  		       model.property :vat_standard, DataMapper::Property::Decimal, precision: 10, scale: 2
  		       model.property :taxes_standard, DataMapper::Property::Decimal, precision: 10, scale: 2
  		       model.property :vat_reduced, DataMapper::Property::Decimal, precision: 10, scale: 2
  		       model.property :taxes_reduced, DataMapper::Property::Decimal, precision: 10, scale: 2
  		       model.property :vat_reduced_2, DataMapper::Property::Decimal, precision: 10, scale: 2
  		       model.property :taxes_reduced_2, DataMapper::Property::Decimal, precision: 10, scale: 2
  		       model.property :vat_reduced_3, DataMapper::Property::Decimal, precision: 10, scale: 2
  		       model.property :taxes_reduced_3, DataMapper::Property::Decimal, precision: 10, scale: 2

  		       model.property :subtotal, DataMapper::Property::Decimal, precision: 10, scale: 2
  		       model.property :total_taxes, DataMapper::Property::Decimal, precision: 10, scale: 2
	           model.property :total, DataMapper::Property::Decimal, precision: 10, scale: 2
           end

	    end

        #
        # Add item data to the totals
        #
	    def add_item_data(item_totals, taxes)

              init_totals
              init_taxes(taxes)

              self.total_without_taxes_standard += item_totals.total_without_taxes if item_totals.vat_type == 'standard' 
              self.total_without_taxes_reduced += item_totals.total_without_taxes if item_totals.vat_type == 'reduced'
              self.total_without_taxes_reduced_2 += item_totals.total_without_taxes if item_totals.vat_type == 'reduced_2'
              self.total_without_taxes_reduced_3 += item_totals.total_without_taxes if item_totals.vat_type == 'reduced_3'    
              
              self.taxes_standard += item_totals.taxes if item_totals.vat_type == 'standard' 
              self.taxes_reduced += item_totals.taxes if item_totals.vat_type == 'reduced'
              self.taxes_reduced_2 += item_totals.taxes if item_totals.vat_type == 'reduced_2'
              self.taxes_reduced_3 += item_totals.taxes if item_totals.vat_type == 'reduced_3'

              self.subtotal += item_totals.total_without_taxes
              self.total_taxes += item_totals.taxes
              self.total += item_totals.total              
	    end
	    
	    #
	    # Update item data to the totals
	    #
        def update_item_data(item_totals, old_item_totals, taxes)

              init_totals
              init_taxes(taxes)

              substract_item_data(old_item_totals, taxes)
              add_item_data(item_totals, taxes)

        end	

	    #
	    # Substract item data to the totals
	    #
	    def substract_item_data(item_totals, taxes)

              init_totals
              init_taxes(taxes)

              self.total_without_taxes_standard -= item_totals.total_without_taxes if item_totals.vat_type == 'standard' 
              self.total_without_taxes_reduced -= item_totals.total_without_taxes if item_totals.vat_type == 'reduced'
              self.total_without_taxes_reduced_2 -= item_totals.total_without_taxes if item_totals.vat_type == 'reduced_2'
              self.total_without_taxes_reduced_3 -= item_totals.total_without_taxes if item_totals.vat_type == 'reduced_3'    
              
              self.taxes_standard -= item_totals.taxes if item_totals.vat_type == 'standard' 
              self.taxes_reduced -= item_totals.taxes if item_totals.vat_type == 'reduced'
              self.taxes_reduced_2 -= item_totals.taxes if item_totals.vat_type == 'reduced_2'
              self.taxes_reduced_3 -= item_totals.taxes if item_totals.vat_type == 'reduced_3'

              self.subtotal -= item_totals.total_without_taxes
              self.total_taxes -= item_totals.taxes
              self.total -= item_totals.total
	    end 	

	    private

	    def init_totals
	    	  self.total_without_taxes_standard ||= 0
          self.total_without_taxes_reduced ||= 0
          self.total_without_taxes_reduced_2 ||= 0
          self.total_without_taxes_reduced_3 ||= 0
          self.taxes_standard ||= 0
          self.taxes_reduced ||= 0
          self.taxes_reduced_2 ||= 0
          self.taxes_reduced_3 ||= 0
          self.subtotal ||= 0
          self.total_taxes ||= 0
          self.total ||= 0
	    end

	    def init_taxes(taxes)
              self.vat_standard = taxes.vat_standard if self.vat_standard.nil?
              self.vat_reduced = taxes.vat_reduced if self.vat_reduced.nil?
              self.vat_reduced_2 = taxes.vat_reduced_2 if self.vat_reduced_2.nil?
              self.vat_reduced_3 = taxes.vat_reduced_3 if self.vat_reduced_3.nil?
	    end	

	  end
	end
  end
end  	
	    	