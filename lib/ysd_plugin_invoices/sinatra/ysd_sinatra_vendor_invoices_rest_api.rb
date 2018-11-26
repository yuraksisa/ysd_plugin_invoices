#
# Middleware functionality
#
module Sinatra
 module YSD 
   module VendorInvoicesRestApi
    
     def self.registered(app)
      
       #
       # Create a new vendor invoice 
       #
       app.post '/api/invoices/vendor-invoices', :allowed_usergroups => ['staff'] do 

       end

     end
    end #VendorInvoices 
 end #YSD
end #Sinatra
