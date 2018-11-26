module Yito 
  module Model	
	  module Invoices
	  	#
	  	# Represent taxes
	  	#
	  	class Taxes
	  	   include DataMapper::Resource

	       storage_names[:default] = 'invoiceds_taxes'

	       property :id, Serial
	       property :name, String, length: 100, :unique_index => :invoiceds_taxes_name_idx
	       property :country_code, String, length: 3
	       property :vat_standard, Decimal, precision: 10, scale: 2
	       property :apply_vat_reduced, Boolean
	       property :vat_reduced, Decimal, precision: 10, scale: 2
	       property :apply_vat_reduced_2, Boolean
	       property :vat_reduced_2, Decimal, precision: 10, scale: 2
	       property :apply_vat_reduced_3, Boolean
	       property :vat_reduced_3, Decimal, precision: 10, scale: 2
	       property :apply_vat_zero, Boolean

	       #
	       # Get the vat types
	       #
	       def vat_types
	         result = {	standard: YsdPluginInvoices.r18n.t.taxes.vat_standard }
	         result.store(:reduced, YsdPluginInvoices.r18n.t.taxes.vat_reduced) if apply_vat_reduced
	         result.store(:reduced_2, YsdPluginInvoices.r18n.t.taxes.vat_reduced_2) if apply_vat_reduced_2
	         result.store(:reduced_3, YsdPluginInvoices.r18n.t.taxes.vat_reduced_3) if apply_vat_reduced_3
	         result.store(:zero, YsdPluginInvoices.r18n.t.taxes.vat_zero) if apply_vat_zero
	         return result
	       end	

           #
           # Get the vat percentage for the vat type
           # 
	       def vat_percentage(vat_type)
             
             vat_percentage = case vat_type
	                             when 'standard'
	                                self.vat_standard
	                             when 'reduced'
	                                self.vat_reduced
	                             when 'reduced_2'
	                                self.vat_reduced_2
	                             when 'reduced_3'
	                                self.vat_reduced_3
	                             when 'zero'
	                                0
                              end    
	       end	

	  	end
	  end	
  end
end