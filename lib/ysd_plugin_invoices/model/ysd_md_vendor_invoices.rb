require 'data_mapper' unless defined?DataMapper::Resource

module Yito
  module Model
    module Invoices
      class VendorInvoice
        include DataMapper::Resource

        storage_names[:default] = 'invoiceds_vendor_invoices'
        
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

        has n, :items, 'VendorInvoiceItem', :child_key => [:vendor_invoice_id], :parent_key => [:id]

        belongs_to :rectificated_invoice, 'VendorInvoice', required: false

      end
    end
  end
end