require 'ysd-plugins' unless defined?Plugins::Plugin

Plugins::SinatraAppPlugin.register :invoices do

   name=        'invoices'
   author=      'yurak sisa'
   description= 'Integrate invoices'
   version=     '0.1'
   sinatra_extension Sinatra::YSD::Invoices  
   sinatra_extension Sinatra::YSD::CustomerInvoices
   sinatra_extension Sinatra::YSD::CustomerInvoicesRestApi  
   sinatra_extension Sinatra::YSD::VendorInvoices
   sinatra_extension Sinatra::YSD::VendorInvoicesRestApi                 
   hooker            Huasi::InvoicesExtension
  
end