#
# Middleware functionality
#
module Sinatra
 module YSD 
   module VendorInvoices
    
     def self.registered(app)
      
       #
       # Simple vendor invoice
       #
       app.get '/admin/invoices/vendor-invoices/new-simple', :allowed_usergroups => ['staff'] do 
          
          load_page :new_simple_vendor_invoice

       end

     end
    end #VendorInvoices 
 end #YSD
end #Sinatra
