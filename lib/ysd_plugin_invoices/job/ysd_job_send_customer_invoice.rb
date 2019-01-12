require 'ysd_service_postal' unless defined?PostalService

module Job
  class SendCustomerInvoiceJob

    def initialize(invoice_id, smtp_settings=nil)
    	@invoice_id = invoice_id
    	@smtp_settings = smtp_settings
    end

    def perform
    
      if @invoice = ::Yito::Model::Invoices::CustomerInvoice.get(@invoice_id) and @invoice.customer	

	      # Company data
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

          # Build the message        
      	  body = YsdPluginInvoices.r18n.t.invoices_mailer.body(@invoice.customer_full_name, 
      	  													   company[:name], 
      	  													   company[:name])	
      	  message= { to: @invoice.customer.email, 
	      			 subject: YsdPluginInvoices.r18n.t.invoices_mailer.subject
      	  		   }
      	  message.merge!(@smtp_settings) unless @smtp_setting.nil?
      	  message.merge!(build_message(body))
      	  message.merge!(build_attachment(company))

      	  # Send the message	
	      PostalService.post(message)

	  	  # Update the invoice	
	  	  now = DateTime.now
	      @invoice.update(invoice_sent: true, invoice_sent_date: now)
	      ::Yito::Model::Newsfeed::Newsfeed.create(category: 'invoicing',
                    action: 'notification_sent',
                    identifier: @invoice.id.to_s,
                    description: YsdPluginInvoices.r18n.t.invoices_newsfeed.notification_sent(@invoice.customer.email),
                    attributes_updated: {invoice_sent: true, invoice_sent_date: now})


  	  end

    end

    private

    # Build the message
    #
    def build_message(message)

	    post_message = {}
	      
	    if message.match /<\w+>/
	      post_message.store(:html_body, message) 
	    else
	      post_message.store(:body, message)
	    end 
	      
	    return post_message

    end    

    # Build the attachment
    #
    def build_attachment(company)

      	# Build the pdf
      	invoice_pdf = ::Yito::Model::Invoices::Pdf::CustomerInvoice.new(@invoice, company, '')
      	post_attachments = {attachments: {'invoice.pdf' => invoice_pdf.build.render}}	

      	return post_attachments

    end	

  end
end    	