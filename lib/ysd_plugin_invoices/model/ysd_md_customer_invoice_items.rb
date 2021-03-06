require 'data_mapper' unless defined?DataMapper::Resource

module Yito
  module Model
    module Invoices
      class CustomerInvoiceItem
        include DataMapper::Resource

        storage_names[:default] = 'invoiceds_customer_invoice_items'

        property :id, Serial
        property :concept, String, length: 256

        include Yito::Concern::Invoices::ItemTotals

        belongs_to :customer_invoice, 'CustomerInvoice', :child_key => [:customer_invoice_id], :parent_key => [:id]

      end
    end
  end
end