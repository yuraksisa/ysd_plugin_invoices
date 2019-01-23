require 'data_mapper' unless defined?DataMapper
require 'ysd_md_payment' unless defined?Payments::Charge

module Yito
  module Model
    module Invoices
      class CustomerInvoiceCharge
        include DataMapper::Resource

        storage_names[:default] = 'invoiceds_customer_invoice_charges'

        belongs_to :customer_invoice, 'CustomerInvoice', :child_key => [:customer_invoice_id], :parent_key => [:id], :key => true
        belongs_to :charge, 'Payments::Charge', :child_key => [:charge_id], :parent_key => [:id], :key => true
    
        #
        # Retrieve the order associated with a charge
        # 
        def self.customer_invoice_from_charge(charge_id)

          if customer_invoice_charge = first(:charge => {:id => charge_id })
            customer_invoice_charge.customer_invoice
          end

        end 

        #
        # Integration with charges (return the charge detail)
        #
        # @return [Array]
        def charge_detail
      
          @charge_detail ||= if order 
                               build_full_charge_detail
                             else
                               []
                             end

        end
    
        #
        # Integration with charges. When the charge is going to be charged, notifies
        # the sources
        #
        def charge_in_process

          # None

        end

        #
        # Integration with charges
        #
        def charge_source
          customer_invoice
        end
    
        #
        # Integration with charges
        #
        def charge_source_description
      
          if customer_invoice and customer_invoice.id
            if customer_invoice.invoice_type == :invoice
              YsdPluginInvoices.r18n.t.customer_invoice_model.charge_description(customer_invoice.id)
            else
              YsdPluginInvoices.r18n.t.customer_invoice_model.payment_description(customer_invoice.id)
            end  
          end

        end
     
        #
        # Integration with charges
        # 
        def charge_source_url
          if customer_invoice and customer_invoice.id
            "/admin/invoices/customer-invoices/#{customer_invoice.id}"
          end
        end

        def as_json(opts={})

          methods = opts[:methods] || []
          methods << :charge_source_description
          methods << :charge_source_url

          super(opts.merge(:methods => methods))

        end


        private 
    
        #
        # Builds a full charge detail
        #
        # @return [Array]
        def build_full_charge_detail

          charge_detail = []
          customer_invoice.items.each do |item|
            charge_detail << {:item_reference => item.concept,
                              :item_description => item.concept,
                              :item_units => item.quantity,
                              :item_price => item.total}
          end
      
          return charge_detail
        end
      end
    end
  end
end

module Payments
  class Charge
    has 1, :customer_invoice_charge_source, 'Yito::Model::Invoices::CustomerInvoiceCharge', :constraint => :destroy
  end
end