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
        
        # Information about the scheduled payment
        property :payment_method, String # cheque - efectivo - transferencia - pagaré
        property :payment_term, String   # 0 - 15 - 30 - 60 - 90
        property :expected_payment_date, Date

        # Information about the payments
        property :payment_on_account, Decimal, precision: 10, scale: 2, default: 0
        property :payment_status, Enum[:pending, :paid], default: :pending
        property :total_paid, Decimal, precision: 10, scale: 2, default: 0
        property :total_pending, Decimal, precision: 10, scale: 2, default: 0  
            
        property :reference_source, String, length: 100
        property :reference, String, length: 100

        belongs_to :customer, 'Yito::Model::Customers::Customer', :child_key => [:customer_id], :parent_key => [:id]

        property :customer_type, Enum[:individual, :legal_entity], default: :individual
        property :customer_full_name, String, length: 100
        property :customer_document_id, String, length: 50
        belongs_to :customer_address, 'LocationDataSystem::Address', required: false 

        include Yito::Concern::Invoices::Totals

        has n, :items, 'CustomerInvoiceItem', :child_key => [:customer_invoice_id], :parent_key => [:id], :constraint => :destroy

        belongs_to :rectificated_invoice, 'CustomerInvoice', required: false

        property :invoice_type, Enum[:invoice, :payment], default: :invoice
        property :invoice_status, Enum[:draft, :invoice], default: :draft

        property :notes, Text

        property :invoice_sent, Boolean, default: false
        property :invoice_sent_date, DateTime

        has n, :customer_invoice_charges, 'CustomerInvoiceCharge', :child_key => [:customer_invoice_id], :parent_key => [:id]
        has n, :charges, 'Payments::Charge', :through => :customer_invoice_charges

        extend Yito::Model::Finder

        before :create do |customer_invoice|
          # Copy customer data  
          customer_invoice.copy_customer_data if customer_invoice.customer
        end            

        def self.payment_methods
          {cash: YsdPluginInvoices.r18n.t.invoices_payment_methods.cash,
           bank_transfer: YsdPluginInvoices.r18n.t.invoices_payment_methods.bank_transfer,
           credit_card: YsdPluginInvoices.r18n.t.invoices_payment_methods.credit_card,
           check: YsdPluginInvoices.r18n.t.invoices_payment_methods.check,
           promissory_note: YsdPluginInvoices.r18n.t.invoices_payment_methods.promissory_note}
        end

        # 
        # Copy customer data into the invoice
        #
        def copy_customer_data

            if self.invoice_status != :invoice
                if self.customer
                    self.customer_type = self.customer.customer_type
                    if self.customer.customer_type == :individual
                      self.customer_full_name = self.customer.full_name
                      self.customer_document_id = self.customer.document_id
                    elsif self.customer.customer_type == :legal_entity
                      self.customer_full_name = self.customer.company_name
                      self.customer_document_id = self.customer.company_document_id
                    end
                    if self.customer.invoice_address
                        self.customer_address = LocationDataSystem::Address.new if self.customer_address.nil?
                        self.customer_address.street = self.customer.invoice_address.street
                        self.customer_address.number = self.customer.invoice_address.number
                        self.customer_address.complement = self.customer.invoice_address.complement
                        self.customer_address.city = self.customer.invoice_address.city
                        self.customer_address.state = self.customer.invoice_address.state
                        self.customer_address.zip = self.customer.invoice_address.zip
                        self.customer_address.country = self.customer.invoice_address.country
                        self.customer_address.save
                    end 
                end   
            end

        end    

        #
        # Generate bill
        # ---------------------------------------------------------------------
        #
        def generate_bill

          if invoice_status == :draft
    
            if next_value = SystemConfiguration::Counter.next_value('customer_invoices', self.serie)
              self.number = next_value
              self.invoice_status = :invoice
              self.save
              ::Yito::Model::Newsfeed::Newsfeed.create(category: 'invoicing',
                    action: 'bill_generated',
                    identifier: self.id.to_s,
                    description: YsdPluginInvoices.r18n.t.invoices_newsfeed.bill_generated,
                    attributes_updated: {invoice_status: :invoice, number: next_value})
            end  
          end  

        end  

        #
        # Add an invoice item
        #
        # == Parameters::
        #
        # concept:: The invoice item concept
        # vat_type:: Vat type
        # taxes:: Instance of Yito::Model::Invoices::Taxes that represent the current taxes
        # quantity:: The quantity
        # price:: The price
        # taxes_included:: The price includes the taxes 
        #
        def add_invoice_item(concept, vat_type, taxes, quantity, price, taxes_included)
  
          vat_percentage = taxes.vat_percentage(vat_type.to_s)
          vat_tp = vat_percentage.to_f / 100

          if taxes_included
            price_without_taxes = (price / (1+vat_tp)).round(2)
            unit_taxes = price - price_without_taxes
          else
            price_without_taxes = price
            unit_taxes = (price_without_taxes * vat_tp).round(2)
          end  

          # Create the invoice item
          invoice_item = CustomerInvoiceItem.new
          invoice_item.concept = concept
          invoice_item.vat_type = vat_type
          invoice_item.vat_percentage = vat_percentage
          invoice_item.quantity = quantity
          # Unitary
          invoice_item.price_without_taxes = price_without_taxes
          invoice_item.unit_taxes = unit_taxes
          # Totals
          invoice_item.total = ((price_without_taxes + unit_taxes) * quantity).round(2)
          invoice_item.total_without_taxes = (price_without_taxes * quantity).round(2)
          invoice_item.subtotal = invoice_item.total_without_taxes
          invoice_item.taxes = invoice_item.total - invoice_item.subtotal
          # Invoice
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
        def update_invoice_item(id, concept, vat_type, taxes, quantity, price, taxes_included)

           if invoice_item = CustomerInvoiceItem.get(id)

              vat_percentage = taxes.vat_percentage(vat_type.to_s)
              vat_tp = vat_percentage.to_f / 100

              if taxes_included
                price_without_taxes = (price / (1+vat_tp)).round(2)
                unit_taxes = price - price_without_taxes
              else
                price_without_taxes = price
                unit_taxes = (price_without_taxes * vat_tp).round(2)
              end  

              old_invoice_item = invoice_item.clone
              invoice_item.concept = concept
              invoice_item.vat_type = vat_type
              invoice_item.vat_percentage = vat_percentage
              invoice_item.quantity = quantity
              # Unitary
              invoice_item.price_without_taxes = price_without_taxes
              invoice_item.unit_taxes = unit_taxes
              # Totals
              invoice_item.total = ((price_without_taxes + unit_taxes) * quantity).round(2)
              invoice_item.total_without_taxes = (price_without_taxes * quantity).round(2)
              invoice_item.subtotal = invoice_item.total_without_taxes
              invoice_item.taxes = invoice_item.total - invoice_item.subtotal
              # Save invoice item
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
             relationships.store(:charges, {})
             super(options.merge({:relationships => relationships}))
           end

        end
   
      end
    end
  end
end