#
# Middleware functionality
#
module Sinatra
 module YSD 
   module CustomerInvoicesRestApi
    
     def self.registered(app)
     
        # ------------------------------- CUSTOMER INVOICES --------------------------

        #                    
        # Query customer-invoices
        #
        ["/api/customer-invoices","/api/customer-invoices/page/:page"].each do |path|
          
          app.post path, :allowed_usergroups => ['bookings_manager','staff'] do

            page = [params[:page].to_i, 1].max
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:date.desc]}

            if request.media_type == "application/json"
              request.body.rewind
              search_request = JSON.parse(URI.unescape(request.body.read))

              if search_request.has_key?('invoice_status') and ['draft', 'invoice'].include?(search_request['invoice_status'])
                if search_request['invoice_status'] == 'draft'
                  data,total  = ::Yito::Model::Invoices::CustomerInvoice.all_and_count({conditions: {invoice_status: :draft}}.merge(offset_order_query))	 
                elsif search_request['invoice_status'] == 'invoice'
                  data,total  = ::Yito::Model::Invoices::CustomerInvoice.all_and_count({conditions: {invoice_status: :invoice}}.merge(offset_order_query))	
                else
                  data,total  = ::Yito::Model::Invoices::CustomerInvoice.all_and_count(offset_order_query)	
                end   	
              elsif search_request.has_key?('search') and (search_request['search'].to_s.strip.length > 0)	
                search_text = search_request['search']
                conditions = Conditions::JoinComparison.new('$or',
                                                          [Conditions::Comparison.new(:customer_full_name, '$like', "%#{search_text}%"),
                                                           Conditions::Comparison.new(:customer_document_id, '$like', "%#{search_text}%"),	
                                                           Conditions::Comparison.new(:reference, '$eq', search_text),
                                                           Conditions::Comparison.new(:concept, '$like', "%#{search_text}%"),
                                                           Conditions::Comparison.new(:number, '$eq', search_text.to_i),
                                                           ])
                total = conditions.build_datamapper(::Yito::Model::Invoices::CustomerInvoice).all.count
                data = conditions.build_datamapper(::Yito::Model::Invoices::CustomerInvoice).all(offset_order_query)
              else
              	data,total  = ::Yito::Model::Invoices::CustomerInvoice.all_and_count(offset_order_query)
              end  
            else
              data,total  = ::Yito::Model::Invoices::CustomerInvoice.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get a customer invoice
        #
        app.get "/api/customer-invoice/:id", :allowed_usergroups => ['bookings_manager','staff'] do
        
          data = ::Yito::Model::Invoices::CustomerInvoice.get(params[:id].to_i)
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a customer invoice
        #
        app.post "/api/customer-invoice", :allowed_usergroups => ['bookings_manager','staff'] do
        
          data_request = body_as_json(::Yito::Model::Invoices::CustomerInvoice)
          data = ::Yito::Model::Invoices::CustomerInvoice.create(data_request)
         
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a customer invoice
        #
        app.put "/api/customer-invoice", :allowed_usergroups => ['bookings_manager','staff'] do
          
          data_request = body_as_json(::Yito::Model::Invoices::CustomerInvoice)
                              
          if data = ::Yito::Model::Invoices::CustomerInvoice.get(data_request.delete(:id))
            data.transaction do
              copy_customer_data = (data_request[:customer_id].to_i != data.customer_id)
              data.attributes=data_request  
              data.copy_customer_data if copy_customer_data
              data.save
            end
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes a customer invoice
        #
        app.delete "/api/customer-invoice", :allowed_usergroups => ['bookings_manager','staff'] do
        
          data_request = body_as_json(::Yito::Model::Invoices::CustomerInvoice)
          
          key = data_request.delete(:id).to_i
                    
          if data = ::Yito::Model::Invoices::CustomerInvoice.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

        #
        # Add a customer invoice item
        #
        app.post '/api/customer-invoice/:invoice_id/invoice-item', :allowed_usergroups => ['bookings_manager', 'staff'] do
           
           if @invoice = ::Yito::Model::Invoices::CustomerInvoice.get(params[:invoice_id])
             @taxes = ::Yito::Model::Invoices::Taxes.first(name: 'taxes.default')
             request.body.rewind
             data_request = JSON.parse(URI.unescape(request.body.read))
             data_request.symbolize_keys!             
             @invoice.transaction do
               result = @invoice.add_invoice_item(data_request[:concept], 
             	                                    data_request[:vat_type].to_sym,
             	                                    @taxes,
             	                                    data_request[:quantity].to_i,
             	                                    BigDecimal.new(data_request[:price]),
                                                  data_request[:taxes_included])
               content_type :json
               result.to_json
             end  
           else
           	 status 404
           end	

        end

        #
        # Update a customer invoice item
        #
        app.put '/api/customer-invoice/:invoice_id/invoice-item/:id', :allowed_usergroups => ['bookings_manager', 'staff'] do

           if @invoice = ::Yito::Model::Invoices::CustomerInvoice.get(params[:invoice_id])
             @taxes = ::Yito::Model::Invoices::Taxes.first(name: 'taxes.default')
             request.body.rewind
             data_request = JSON.parse(URI.unescape(request.body.read))
             data_request.symbolize_keys! 
             @invoice.transaction do
               result = @invoice.update_invoice_item(params[:id],
               	                                     data_request[:concept],
               	                                     data_request[:vat_type].to_sym,
               	                                     @taxes,
               	                                     data_request[:quantity].to_i,
               	                                     BigDecimal.new(data_request[:price]),
                                                     data_request[:taxes_included])
               content_type :json
               result.to_json               
             end             
           else
             status 404
           end  	

        end

        #
        # Delete a customer invoice item
        #
        app.delete '/api/customer-invoice/:invoice_id/invoice-item/:id', :allowed_usergroups => ['bookings_manager', 'staff'] do

           if @invoice = ::Yito::Model::Invoices::CustomerInvoice.get(params[:invoice_id])
           	 @taxes = ::Yito::Model::Invoices::Taxes.first(name: 'taxes.default')
             @invoice.transaction do
               result = @invoice.destroy_invoice_item(params[:id], @taxes)
               content_type :json
               result.to_json
             end  
           else
             status 404  
           end
  
        end

        # -------------------------- MANAGING INVOICES -----------------

        #
        # Generate a bill
        #
        app.post '/api/customer-invoice/:invoice_id/generate-bill', allowed_usergroups: ['bookings_manager', 'staff'] do

          if invoice = ::Yito::Model::Invoices::CustomerInvoice.get(params[:invoice_id])
            # Generate the bill
            invoice.transaction do
              invoice.generate_bill
            end  
            status 200
            content_type :json
            invoice.to_json
          else
            status 404  
          end  

        end  

        #
        # Send a invoice
        #
        app.post '/api/customer-invoice/:invoice_id/send-invoice', allowed_usergroups: ['booking_manager', 'staff'] do

          if invoice = ::Yito::Model::Invoices::CustomerInvoice.get(params[:invoice_id])
            #::Delayed::Job.enqueue Job::SendCustomerInvoiceJob.new(invoice.id)
            Job::SendCustomerInvoiceJob.new(invoice.id).perform
            invoice.reload
            status 200
            content_type :json
            invoice.to_json
          end  

        end          

        # -------------------------- CHARGES ---------------------------

        #
        # Register a charge
        #
        app.post '/api/customer-invoice/:id/charge', :allowed_usergroups => ['bookings_manager', 'booking_operator', 'staff'] do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys!

          if invoice = ::Yito::Model::Invoices::CustomerInvoice.get(params[:id])

            invoice.transaction do
              # Create the charge
              charge = Payments::Charge.new
              if invoice.invoice_type == :payment
                charge.payment_type = :payment
                charge.amount = -1 * BigDecimal.new(data[:amount])
              else
                charge.payment_type = :charge
                charge.amount = data[:amount]
              end  
              charge.date = data[:date]
              charge.payment_method_id = data[:payment_method_id]
              charge.status = :done
              charge.currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')
              charge.save
              # Create the invoice-charge
              invoice_charge = ::Yito::Model::Invoices::CustomerInvoiceCharge.new
              invoice_charge.customer_invoice = invoice
              invoice_charge.charge = charge
              invoice_charge.save
              # Update the invoice
              invoice.total_paid += charge.amount
              invoice.total_pending -= charge.amount
              invoice.total_pending = 0 if invoice.total_pending < 0
              invoice.payment_status = :paid if invoice.total_pending == 0
              invoice.save
              # Newsfeed
              ::Yito::Model::Newsfeed::Newsfeed.create(category: 'invoicing',
                    action: 'add_customer_invoice_charge',
                    identifier: invoice.id.to_s,
                    description: YsdPluginInvoices.r18n.t.invoices_newsfeed.added_invoice_charge("%.2f" % charge.amount, charge.payment_method_id),
                    attributes_updated: {total_paid: invoice.total_paid, total_pending: invoice.total_pending, payment_status: invoice.payment_status}.to_json)
              invoice.reload
            end
            content_type :json
            status 200
            invoice.to_json
          else
            status 404
          end

        end

        #
        # Delete a charge
        #
        app.delete '/api/customer-invoice/:id/charge/:charge_id', :allowed_usergroups => ['booking_manager', 'booking_operator', 'staff'] do
          
          if invoice_charge = ::Yito::Model::Invoices::CustomerInvoiceCharge.first(:customer_invoice_id => params[:id],
                                                                                   :charge_id => params[:charge_id])
            invoice = invoice_charge.customer_invoice

            old_total_paid = invoice.total_paid
            old_total_pending = invoice.total_pending

            charge = invoice_charge.charge

            invoice_charge.transaction do
              # Updat the invoice
              invoice.total_paid -= charge.amount
              invoice.total_pending += charge.amount
              invoice.payment_status = :pending if invoice.total_pending > 0
              invoice.save
              # Destroy the charge
              charge.destroy
              invoice_charge.destroy
              # Newsfeed   
              ::Yito::Model::Newsfeed::Newsfeed.create(category: 'invoicing',
                                                       action: 'destroyed_customer_invoice_charge',
                                                       identifier: invoice.id.to_s,
                                                       description: YsdPluginInvoices.r18n.t.invoices_newsfeed.destroyed_invoice_charge("%.2f" % charge.amount, charge.payment_method_id),
                                                       attributes_updated: {total_paid: invoice.total_paid, total_pending: invoice.total_pending, payment_status: invoice.payment_status}.to_json)
            end
            invoice.reload
            content_type :json
            invoice.to_json
          else
            logger.error("Customer invoice charge #{params[:charge_id]} for #{params[:customer_invoice_id]} not found")
            status 404
          end

        end

     end

   end
 end
end      	