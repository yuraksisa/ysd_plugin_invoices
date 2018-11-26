require 'data_mapper' unless defined?DataMapper::Resource

module Yito
  module Model
    module Invoices
      class VendorInvoiceItem
        include DataMapper::Resource

        storage_names[:default] = 'invoiceds_vendor_invoice_items'

        property :id, Serial
        property :concept, String, length: 256

        include Yito::Concern::Invoices::ItemTotals

        belongs_to :vendor_invoice, 'VendorInvoice', :child_key => [:vendor_invoice_id], :parent_key => [:id]

      end
    end
  end
end