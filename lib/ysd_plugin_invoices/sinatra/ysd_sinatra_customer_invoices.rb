#
# Middleware functionality
#
module Sinatra
 module YSD 
   module CustomerInvoices
    
     def self.registered(app)

        #
        # Print an invoice
        #
        app.get '/admin/invoices/customer-invoices/:id.pdf', :allowed_usergroups => ['booking_manager','staff'] do
          
          if @customer_invoice = ::Yito::Model::Invoices::CustomerInvoice.get(params[:id])
            company = {
                        name: SystemConfiguration::Variable.get_value('site.company.name'),
                        document_id: SystemConfiguration::Variable.get_value('site.company.document_id'),
                        phone_number: SystemConfiguration::Variable.get_value('site.company.phone_number'),
                        email: SystemConfiguration::Variable.get_value('site.company.email'),
                        address_1: SystemConfiguration::Variable.get_value('site.company.address_1'),
                        address_2: SystemConfiguration::Variable.get_value('site.company.address_2'),
                        city: SystemConfiguration::Variable.get_value('site.company.city'),
                        state: SystemConfiguration::Variable.get_value('site.company.state'),
                        zip: SystemConfiguration::Variable.get_value('site.company.zip'),
                        country: SystemConfiguration::Variable.get_value('site.company.country')
                      }
            pdf = ::Yito::Model::Invoices::Pdf::CustomerInvoice.new(@customer_invoice, company, '').build.render
            content_type 'application/pdf'
            pdf
          else
            status 404
          end    

        end  

        #
        # Customer invoice list
        #
        app.get '/admin/invoices/customer-invoices/list', allowed_usergroups: ['booking_manager','staff'] do
          if params[:reference_source] and params[:reference]
            @invoices = ::Yito::Model::Invoices::CustomerInvoice.all(conditions: {reference_source: params[:reference_source],
                                                                                  reference: params[:reference]},
                                                                     order: [:number.desc, :date.desc])
            load_page :invoices_list
          else
            status 404
          end  
        end  

        #
        # Customer invoices management
        #
        app.get '/admin/invoices/customer-invoices/?*', :allowed_usergroups => ['booking_manager','staff'] do

          locals = {:per_page => 20}
          @series = SystemConfiguration::Counter.series('customer_invoices')
          @taxes = ::Yito::Model::Invoices::Taxes.first(name: 'taxes.default')
          @sources = Plugins::Plugin.plugin_invoke_all('invoice_sources', {:app => self})
          @concept = ::Yito::Model::Classifier::ClassifierTaxonomy.first({name: 'customer_invoice_concepts'})
          load_em_page :invoices,
                       :customer_invoices, false, :locals => locals

        end


     end
    end #CustomersManagement 
 end #YSD
end #Sinatra
