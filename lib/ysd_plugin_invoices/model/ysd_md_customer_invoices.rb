require 'data_mapper' unless defined?DataMapper::Resource

module Yito
  module Model
    module Invoices
      class CustomerInvoice
        include DataMapper::Resource

        storage_names[:default] = 'invoiceds_customer_invoices' 

        property :id, Serial
        property :serie, String, length: 10
        property :number, Integer
        property :date, DateTime

        property :concept, Text
        property :payment_method, String
        property :payment_term, String    
            
        property :reference_source, String, length: 100
        property :reference, String, length: 100

        belongs_to :customer, 'Yito::Model::Customers::Customer', :child_key => [:customer_id], :parent_key => [:id]

        property :customer_full_name, String, length: 100
        property :customer_document_id, String, length: 50
        belongs_to :customer_address, 'LocationDataSystem::Address', required: false 

        include Yito::Concern::Invoices::Totals

        has n, :items, 'CustomerInvoiceItem', :child_key => [:customer_invoice_id], :parent_key => [:id]

        belongs_to :rectificated_invoice, 'CustomerInvoice', required: false

        property :invoice_type, Enum[:invoice, :payment], default: :invoice
        property :invoice_status, Enum[:draft, :invoice], default: :draft

        #
        # Add an invoice item
        #
        def add_invoice_item(concept, vat_type, taxes, quantity, price_without_taxes)
  
          vat_percentage = taxes.vat_percentage(vat_type)

          # Create the invoice item
          invoice_item = CustomerInvoiceItem.new
          invoice_item.concept = concept
          invoice_item.vat_type = vat_type
          invoice_item.vat_percentage = vat_percentage
          invoice_item.quantity = quantity
          invoice_item.price_without_taxes = price_without_taxes
          invoice_item.unit_taxes = (invoice_item.price_without_taxes * vat_percentage) / 100.0
          invoice_item.total_without_taxes = invoice_item.price_without_taxes * quantity
          invoice_item.taxes = invoice_item.total_without_taxes * vat_percentage / 100.0
          invoice_item.total = invoice_item.total_without_taxes + invoice_item.taxes
          invoice_item.customer_invoice = self
          invoice_item.save
          # Update totals
          add_item_data(invoice_item, taxes) 
          # Save and reload the invoice
          self.save
          self.reload
          return self

        end

        #
        # Update invoice item
        #
        def update_invoice_item(id, concept, vat_type, taxes, quantity, price_without_taxes)

           if invoice_item = CustomerInvoiceItem.get(id)
              vat_percentage = taxes.vat_percentage(vat_type)
              old_invoice_item = invoice_item.clone
              invoice_item.concept = concept
              invoice_item.vat_type = vat_type
              invoice_item.vat_percentage = vat_percentage
              invoice_item.quantity = quantity
              invoice_item.price_without_taxes = price_without_taxes
              invoice_item.unit_taxes = (invoice_item.price_without_taxes * vat_percentage) / 100.0
              invoice_item.total_without_taxes = invoice_item.price_without_taxes * quantity
              invoice_item.taxes = invoice_item.total_without_taxes * vat_percentage / 100.0
              invoice_item.total = invoice_item.total_without_taxes + invoice_item.taxes
              invoice_item.customer_invoice = self
              invoice_item.save             
              # Update total
              update_item_data(invoice_item, old_invoice_item, taxes)
              # Save and reload the invoice
              self.save
              self.reload
              return self
           end 

        end    

        #
        # Destroy and invoice item
        #
        def destroy_invoice_item(id, taxes)
           if invoice_item = CustomerInvoiceItem.get(id)
              # Destroy the invoice item  
              invoice_item.destroy
              # Update totals
              substract_item_data(invoice_item, taxes)
              # Save and reload the invoice
              self.save
              self.reload
              return self
           end

        end    

        #
        # Exporting to json
        #
        def as_json(options={})

           if options.has_key?(:only)
             super(options)
           else
             relationships = options[:relationships] || {}
             relationships.store(:customer, {include: [:invoice_address]})
             relationships.store(:items, {})
             relationships.store(:customer_address, {})
             super(options.merge({:relationships => relationships}))
           end

        end
   
      end
    end
  end
end