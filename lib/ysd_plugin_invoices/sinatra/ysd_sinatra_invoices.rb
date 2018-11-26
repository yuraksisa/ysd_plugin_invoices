#
# Middleware functionality
#
module Sinatra
 module YSD 
   module Invoices
    
     def self.registered(app)
      
        # Add the local folders to the views and translations     
        app.settings.views = Array(app.settings.views).push(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'views')))
        app.settings.translations = Array(app.settings.translations).push(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'i18n')))
   
        #
        # Invoice settings
        #
        app.get '/admin/invoices/settings', allowed_usergroups: ['booking_manager', 'staff'] do 

          load_page :invoice_settings

        end 	

     end
    end #Invoices 
 end #YSD
end #Sinatra
