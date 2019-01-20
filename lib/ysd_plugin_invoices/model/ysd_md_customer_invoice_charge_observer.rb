require 'dm-observer' unless defined?DataMapper::Observer
require 'ysd_md_charge' unless defined?Payments::Charge

module Yito
  module Model
    module Invoices
      #
      # Observes changes on the charge tied to the order to update the order
      # status depending on the charge status change
      #
      # - If the charge status is set to done, the order status is set to
      #   confirmed
      #
      # - If the charge status is set to denied, the order status is set to
      #   pending_confirmation
      #	
      class CustomerInvoiceChargeObserver
        include DataMapper::Observer

        observe Payments::Charge
    
        #
        # After creating a charge
        #
        #  - Updates the customer invoice payment_status
        #  - Updates the total_paid and total_pending quantities
        #
        after :create do |charge|

          if charge.charge_source.is_a?Yito::Model::Invoices::CustomerInvoice 
            order = charge.charge_source.customer_invoice
            case charge.status
              when :done
                customer_invoice.total_paid += charge.amount
                customer_invoice.total_pending -= charge.amount
                if (customer_invoice.total_pending == 0)
                  customer_invoice.payment_status = :paid
                end
                customer_invoice.save
              when :denied
                # None
            end
          end
      
        end
      end
    end
  end
end