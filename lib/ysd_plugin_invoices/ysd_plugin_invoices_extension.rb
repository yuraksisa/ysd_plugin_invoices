require 'ysd-plugins_viewlistener' unless defined?Plugins::ViewListener

#
# Social Mail Extension
#
module Huasi

  class InvoicesExtension < Plugins::ViewListener
                
    # ========= Install ==================

    # 
    # Install the plugin
    #
    def install(context={})

       SystemConfiguration::Counter.first_or_create({:name => 'vendor_invoices'}, 
                                                    {:value => 0})

       SystemConfiguration::Counter.first_or_create({:name => 'vendor_simplified_invoices'}, 
                                                    {:value => 0})

       SystemConfiguration::Counter.first_or_create({:name => 'customer_invoices'}, 
                                                    {:value => 0})

       SystemConfiguration::Counter.first_or_create({:name => 'customer_simplified_invoices'}, 
                                                    {:value => 0})

       SystemConfiguration::Variable.first_or_create({:name => 'invoices.customer_invoice_logo'}, 
                                                     {:value => '', :description => 'Customer invoice logo', :module => :invoices})

       ::Yito::Model::Invoices::Taxes.first_or_create({name: 'taxes.default'},
                                                      {country_code: 'ES', vat_standard: 21, 
                                                       apply_vat_reduced: true, vat_reduced: 10,
                                                       apply_vat_reduced_2: true, vat_reduced_2: 4,
                                                       apply_vat_reduced_3: false, vat_reduced_3: nil,
                                                       apply_vat_zero: true })                      
                                                           
    end                                                       
    
  end #IntegrationExtension
end #Social