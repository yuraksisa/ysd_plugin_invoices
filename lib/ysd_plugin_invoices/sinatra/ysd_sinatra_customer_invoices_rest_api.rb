#
# Middleware functionality
#
module Sinatra
 module YSD 
   module CustomerInvoicesRestApi
    
     def self.registered(app)
     
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
              search_text = search_request['search']
              conditions = Conditions::Comparison.new(:concept, '$like', "%#{search_text}%")

              total = conditions.build_datamapper(::Yito::Model::Invoices::CustomerInvoice).all.count
              data = conditions.build_datamapper(::Yito::Model::Invoices::CustomerInvoice).all(offset_order_query)
            else
              data,total  = ::Yito::Model::Invoices::CustomerInvoice.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get all customer invoices
        #
        app.get "/api/customer-invoices", :allowed_usergroups => ['bookings_manager','staff'] do

          data = ::Yito::Model::Invoices::CustomerInvoice.all()

          status 200
          content_type :json
          data.to_json

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
            data.attributes=data_request  
            data.save
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
             data_request = body_as_json(::Yito::Model::Invoices::CustomerInvoiceItem)
             @invoice.transaction do
               result = @invoice.add_invoice_item(data_request[:concept], 
             	                                  data_request[:vat_type],
             	                                  @taxes,
             	                                  data_request[:quantity].to_i,
             	                                  BigDecimal(data_request[:price_without_taxes]))
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
             data_request = body_as_json(::Yito::Model::Invoices::CustomerInvoiceItem)
             @invoice.transaction do
               result = @invoice.update_invoice_item(params[:id],
               	                                     data_request[:concept],
               	                                     data_request[:vat_type],
               	                                     @taxes,
               	                                     data_request[:quantity].to_i,
               	                                     BigDecimal(data_request[:price_without_taxes]))
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

     end

   end
 end
end      	