require "ysd_plugin_invoices/version"

require "ysd_plugin_invoices/model/ysd_md_taxes"
require "ysd_plugin_invoices/concerns/ysd_md_address"
require "ysd_plugin_invoices/concerns/ysd_md_item_totals"
require "ysd_plugin_invoices/concerns/ysd_md_totals"
require "ysd_plugin_invoices/model/ysd_md_vendor_invoices"
require "ysd_plugin_invoices/model/ysd_md_vendor_invoice_items"
require "ysd_plugin_invoices/model/ysd_md_customer_invoices"
require "ysd_plugin_invoices/model/ysd_md_customer_invoice_items"
require "ysd_plugin_invoices/model/ysd_md_vendor_simplified_invoices"
require "ysd_plugin_invoices/model/ysd_md_vendor_simplified_invoice_items"
require "ysd_plugin_invoices/model/ysd_md_customer_simplified_invoices"
require "ysd_plugin_invoices/model/ysd_md_customer_simplified_invoice_items"

require "ysd_plugin_invoices/pdf/ysd_md_customer_invoice_pdf"

require "ysd_plugin_invoices/sinatra/ysd_sinatra_invoices"
require "ysd_plugin_invoices/sinatra/ysd_sinatra_customer_invoices"
require "ysd_plugin_invoices/sinatra/ysd_sinatra_customer_invoices_rest_api"
require "ysd_plugin_invoices/sinatra/ysd_sinatra_vendor_invoices"
require "ysd_plugin_invoices/sinatra/ysd_sinatra_vendor_invoices_rest_api"

require "ysd_plugin_invoices/ysd_plugin_invoices_extension"
require "ysd_plugin_invoices/ysd_plugin_invoices_init"

module YsdPluginInvoices
  # Your code goes here...
  extend Yito::Translation::ModelR18

  def self.r18n(locale=nil)
    path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'i18n'))
    if locale.nil?
      check_r18n!(:invoices_r18n, path)
    else
      R18n::I18n.new(locale, path)
    end
  end
end
