require 'data_mapper' unless defined?DataMapper::Resource

module Yito
  module Model
    module Invoices
      class VendorSimplifiedInvoice
        include DataMapper::Resource

        storage_names[:default] = 'invoiceds_vendor_simplified_invoices'
        
        property :id, Serial
        property :serie, String, length: 10
        property :number, Integer
        property :date, DateTime

        property :concept, Text
        property :payment_method, String
        property :payment_term, String    
                
        property :reference_source, String, length: 100
        property :reference, String, length: 100

        belongs_to :supplier, 'Yito::Model::Suppliers::Supplier', :child_key => [:supplier_id], :parent_key => [:id]

        include Yito::Concern::Invoices::Address
        include Yito::Concern::Invoices::Totals

        has n, :items, 'VendorSimplifiedInvoiceItem', :child_key => [:vendor_simplified_invoice_id], :parent_key => [:id]

      end
    end
  end
end