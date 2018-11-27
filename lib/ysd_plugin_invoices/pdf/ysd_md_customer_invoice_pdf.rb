module Yito
  module Model
    module Invoices
      module Pdf
        class CustomerInvoice

          attr_reader :customer_invoice
          attr_reader :company
          attr_reader :logo_path

          def initialize(customer_invoice, company, logo_path)
            @customer_invoice = customer_invoice
            @company = company
            @logo_path = logo_path
          end	

          def build

            pdf = Prawn::Document.new
            font_file = File.expand_path(File.join(File.dirname(__FILE__), "../../..", "fonts", "DejaVuSans.ttf"))
            font_file_bold = File.expand_path(File.join(File.dirname(__FILE__), "../../..", "fonts", "DejaVuSans-Bold.ttf"))
            pdf.font_families.update({'DejaVuSans' => { :normal => font_file, :bold => font_file_bold}})
            
            # Header =======================

            # ----- Logo -------------------

            logo = SystemConfiguration::Variable.get_value('invoices.customer_invoice_logo')
            root_path = SystemConfiguration::Variable.get_value('media.public_folder_root','')
            base_path = if root_path.empty?
            	          "#{File.join(File.expand_path($0).gsub($0,''))}/public"                          
                        else
                          "#{root_path}/public"
                        end  
            unless logo.empty?
               id = logo.split('/').last
               photo = Media::Photo.get(id)
               logo_path = File.join(base_path, photo.photo_url_full)	
               pdf.image logo_path, width: 300, at: [0, 730]
            end
            	
            # ---- Company ----------------
            
            pdf.text_box "<b>#{company[:name]}</b>", inline_format: true, at: [400, 735], size: 10
            pdf.draw_text "#{company[:address_1]}", at: [400,715], size: 10
            pdf.draw_text "#{company[:zip]} - #{company[:city]} (#{company[:country]})", at:[400, 700], size: 10
            pdf.draw_text "#{company[:email]}", at: [400, 685], size: 10
            pdf.draw_text "#{company[:phone_number]}", at: [400, 670], size: 10
            pdf.draw_text "#{company[:document_id]}", at: [400, 655], size: 10

            # Customer data ==================

            pdf.text_box "#{YsdPluginInvoices.r18n.t.invoices.pdf.invoice_number}: <b>#{customer_invoice.serie}#{customer_invoice.number}</b>", inline_format: true, at: [0, 600], size: 10
            pdf.text_box "#{YsdPluginInvoices.r18n.t.invoices.pdf.date}: <b>#{customer_invoice.date.strftime('%d-%m-%Y')}</b>", inline_format: true, at: [0, 585], size: 10
            pdf.text_box "#{YsdPluginInvoices.r18n.t.invoices.pdf.reference}: <b>#{customer_invoice.reference}</b>", inline_format: true, at:[0, 570], size: 10
            pdf.text_box "#{YsdPluginInvoices.r18n.t.invoices.pdf.customer}: <b>#{customer_invoice.customer_full_name}</b>", inline_format: true, at: [0, 555], size: 10
            pdf.text_box "#{YsdPluginInvoices.r18n.t.invoices.pdf.document_id}: <b>#{customer_invoice.customer_document_id}</b>", inline_format: true, at: [0, 540], size: 10
            pdf.text_box "#{YsdPluginInvoices.r18n.t.invoices.pdf.rectificative}:", inline_format: true, at: [0, 525], size: 10

            pdf.bounding_box([250, 600], :width => 300, :height => 95) do 
              pdf.fill_color 'dddddd'
              pdf.fill_rectangle [0, 0], 300, -95
              pdf.fill_color '000000'
              pdf.stroke_color '000000'
              pdf.stroke_bounds
            end
            
            pdf.bounding_box([255, 595], width: 290, height: 85) do
	              pdf.move_down 5       
	              pdf.text "<b>#{customer_invoice.customer_full_name}</b>", inline_format: true, size:10
	              pdf.move_down 10 
	              pdf.text "<b>#{customer_invoice.customer_address.street} #{customer_invoice.customer_address.number} #{customer_invoice.customer_address.complement}</b>", 
	                       inline_format: true, size:10 if customer_invoice.customer_address
	              pdf.move_down 10 
	              pdf.text "<b>#{customer_invoice.customer_address.zip} #{customer_invoice.customer_address.city} #{customer_invoice.customer_address.state}</b>", 
	                       inline_format: true, size:10  if customer_invoice.customer_address
	              pdf.move_down 10 
	              pdf.text "<b>#{customer_invoice.customer_address.country}</b>", inline_format: true, size:10  if customer_invoice.customer_address
            end

            # Invoice items
            table_data = []
            table_data << ["<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.table.concept}</b>",
            	           "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.table.quantity}</b>",
            	           "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.table.price}</b>",
            	           "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.table.vat_percent}</b>",
            	           "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.table.total}</b>"]
            table_data << [customer_invoice.concept, "", "", "", ""]

            customer_invoice.items.each do |customer_invoice_item|
              table_data << [customer_invoice_item.concept,
                             customer_invoice_item.quantity,
                             "%.2f" % customer_invoice_item.price_without_taxes,
                             "%.2f %%" % customer_invoice_item.vat_percentage,
                             "%.2f" % customer_invoice_item.total ]
            end
            table_data << ["", "", "", "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.subtotal.upcase}</b>", "%.2f" % (customer_invoice.subtotal || 0)]
            table_data << ["", "", "", "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.taxes.upcase}</b>", "%.2f" % (customer_invoice.total_taxes || 0)]
            table_data << ["", "", "", "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.total.upcase}</b>", "%.2f" % (customer_invoice.total || 0)]

            pdf.move_down 50
            pdf.table(table_data, position: :center, width: 560, cell_style: {inline_format: true}) do |t| 
              t.cells.borders = [] 
              t.row(0).background_color = 'eeeeee'         
              #t.columns(0..4).borders = [:right] 	
              #t.columns(0).borders = [:left]
              #t.row(0).borders = [:top, :bottom]
              #t.row(table_data.size-1).borders = [:bottom]
              t.column(0).style(:align => :left, size: 10, width: 250)
              t.column(1).style(:align => :center, size: 10, width: 60)
              t.column(2).style(:align => :right, size: 10, width: 50)          
              t.column(3).style(:align => :right, size: 10, width: 100)
              t.column(4).style(:align => :right, size: 10, width: 100)
            end            

            return pdf

          end          

        end
      end
    end
  end
end

