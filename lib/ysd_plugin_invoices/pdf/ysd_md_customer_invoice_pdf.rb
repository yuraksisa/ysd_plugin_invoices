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

            @preffix_amount = @customer_invoice.invoice_type == :payment ? '-' : ''

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
               pdf.image logo_path, width: 200, height: 40, at: [0, 740]
            end
            	
            # ---- Company ----------------
            
            pdf.bounding_box([400, 745], width: 150, height: 100) do
              pdf.text "<b>#{company[:name]}</b>", inline_format: true, size: 9, align: :right
              pdf.move_down 1
              pdf.text "#{company[:address_1]}", size: 9, align: :right
              pdf.move_down 1
              pdf.text "#{company[:zip]} - #{company[:city]} (#{company[:country]})", size: 9, align: :right
              pdf.move_down 1
              pdf.text "#{company[:email]}", size: 9, align: :right
              pdf.move_down 1
              pdf.text "#{company[:phone_number]}", size: 9, align: :right
              pdf.move_down 2
              pdf.text "#{company[:document_id]}", size: 9, align: :right
            end

            # Invoice summary ==================

            # ---- Invoice number -----------

            pdf.bounding_box([0, 655], width: 70, height: 100) do
              pdf.text "#{YsdPluginInvoices.r18n.t.invoices.pdf.invoice_number.upcase}", inline_format: true, size: 8
              pdf.move_down 3
              pdf.text "#{YsdPluginInvoices.r18n.t.invoices.pdf.date.upcase}", inline_format: true, size: 8
              pdf.move_down 3
              pdf.text "#{YsdPluginInvoices.r18n.t.invoices.pdf.reference.upcase}", inline_format: true, size: 8
              pdf.move_down 3
              pdf.text "#{YsdPluginInvoices.r18n.t.invoices.pdf.customer.upcase}", inline_format: true, size: 8
              pdf.move_down 3
              pdf.text "#{YsdPluginInvoices.r18n.t.invoices.pdf.document_id.upcase}", inline_format: true, size: 8
              pdf.move_down 3
              pdf.text "#{YsdPluginInvoices.r18n.t.invoices.pdf.rectificative.upcase}", inline_format: true, size: 8
            end 

            pdf.bounding_box([70, 655], width: 170 , height: 100) do
              pdf.text ": <b>#{customer_invoice.serie}#{customer_invoice.number}</b>", inline_format: true, size: 8
              pdf.move_down 3
              pdf.text ": <b>#{customer_invoice.date.strftime('%d-%m-%Y')}</b>", inline_format: true, size: 8
              pdf.move_down 3
              pdf.text ": <b>#{customer_invoice.reference}</b>", inline_format: true, size: 8
              pdf.move_down 3
              pdf.text ": <b>#{customer_invoice.customer_full_name}</b>", inline_format: true, size: 8
              pdf.move_down 3
              pdf.text ": <b>#{customer_invoice.customer_document_id}</b>", inline_format: true, size: 8
              pdf.move_down 3
              pdf.text ":", inline_format: true, size: 8
            end 

            # ---- Customer data ------------

            pdf.bounding_box([250, 665], :width => 300, :height => 95) do 
              pdf.fill_color 'dddddd'
              pdf.fill_rectangle [0, 0], 300, -95
              pdf.fill_color '000000'
              pdf.stroke_color '000000'
              pdf.stroke_bounds
            end
            
            pdf.bounding_box([265, 650], width: 290, height: 85) do
	              pdf.move_down 5       
	              pdf.text "<b>#{customer_invoice.customer_full_name}</b>", inline_format: true, size:10
	              pdf.move_down 3 
	              pdf.text "<b>#{customer_invoice.customer_address.street} #{customer_invoice.customer_address.number} #{customer_invoice.customer_address.complement}</b>", 
	                       inline_format: true, size:10 if customer_invoice.customer_address
	              pdf.move_down 3 
	              pdf.text "<b>#{customer_invoice.customer_address.zip} #{customer_invoice.customer_address.city} #{customer_invoice.customer_address.state}</b>", 
	                       inline_format: true, size:10  if customer_invoice.customer_address
	              pdf.move_down 3 
	              pdf.text "<b>#{customer_invoice.customer_address.country}</b>", inline_format: true, size:10  if customer_invoice.customer_address       
            end

            # Invoice items =======================

            table_data = []
            table_data << [
                         "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.table.concept.upcase}</b>",
            	           "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.table.vat_percent.upcase}</b>",
            	           "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.table.total.upcase}</b>"]
            #table_data << [customer_invoice.concept, "", ""]
            customer_invoice.items.each do |customer_invoice_item|
              table_data << [customer_invoice_item.concept,
                             "%.2f %%" % customer_invoice_item.vat_percentage,
                             "#{@preffix_amount}%.2f" % customer_invoice_item.total_without_taxes ]
            end
            table_data << ['',' ',' '] # Last empty row

            pdf.move_down 20
            pdf.table(table_data, position: :center, width: 560, cell_style: {inline_format: true}) do |t| 

              # Header column background
              t.row(0).background_color = 'eeeeee'         
              # Column withs
              t.column(0).style(:align => :left, size: 10, width: 360)       
              t.column(1).style(:align => :right, size: 10, width: 100)
              t.column(2).style(:align => :right, size: 10, width: 100)
              (0..(table_data.size-1)).each do |row_number|
                t.row(row_number).style(height: 25)
              end  
              # Borders
              (1..(table_data.size-1)).each do |row_number|
                if row_number == table_data.size - 1
                  t.row(row_number).borders = [:left, :bottom]
                  t.row(row_number).column(2).borders = [:left, :right, :bottom]
                else  
                  t.row(row_number).borders = [:left]
                  t.row(row_number).column(2).borders = [:left, :right]
                end  
              end    
              # Last row size
              t.row(table_data.size-1).style(height: (table_data.size-4)*25 > 0 ? (225 - ((table_data.size-4) * 25)) : 225 )           
            end            

            # Invoice summary =================

            table_data = []
            table_data << [
                         " ", 
                         "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.subtotal.upcase}</b>",
                         "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.table.vat_percent.upcase}</b>",
                         "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.taxes.upcase}</b>",
                         "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.total.upcase}</b>"]
            table_data << [
                         " ",
                         "#{@preffix_amount}%.2f" % (customer_invoice.subtotal || 0),
                         "#{@preffix_amount}%.2f" % (customer_invoice.vat_standard || 0),
                         "#{@preffix_amount}%.2f" % (customer_invoice.total_taxes || 0),
                         "#{@preffix_amount}%.2f" % (customer_invoice.total || 0)
                        ]             
            table_data << [
                         " ",
                         " ",
                         " ",
                         " ",
                         "#{@preffix_amount}%.2f" % (customer_invoice.total || 0)
                        ]            

            pdf.move_down 20
            pdf.table(table_data, position: :center, width: 560, cell_style: {inline_format: true}) do |t| 
              t.column(0).borders = []
              t.row(0).background_color = 'eeeeee'
              t.row(0).column(0).background_color = 'ffffff'    
              t.column(0).style(:align => :left, size: 10, width: 160) 
              t.column(1).style(:align => :right, size: 10, width: 120)       
              t.column(2).style(:align => :right, size: 10, width: 40)
              t.column(3).style(:align => :right, size: 10, width: 120)
              t.column(4).style(:align => :right, size: 10, width: 120)
              t.row(0).column(0).style(align: :center)
              t.row(0).column(1).style(align: :center)
              t.row(0).column(2).style(align: :center)
              t.row(0).column(3).style(align: :center)
              t.row(table_data.size-2).column(1).borders = [:left, :right]
              t.row(table_data.size-2).column(2).borders = [:left, :right]
              t.row(table_data.size-2).column(3).borders = [:left, :right]              
              t.row(table_data.size-1).column(1).borders = [:left, :bottom, :right]
              t.row(table_data.size-1).column(2).borders = [:left, :bottom, :right]
              t.row(table_data.size-1).column(3).borders = [:left, :bottom, :right]
              t.row(table_data.size-1).column(4).style(size: 20)                 
            end   

            #
            # Notes
            #
            economic_data = ""
            economic_data << if customer_invoice.payment_method 
                               "#{YsdPluginInvoices.r18n.t.invoices.pdf.payment_method.upcase}: <b>#{YsdPluginInvoices.r18n.t.invoices_payment_methods[customer_invoice.payment_method].upcase}</b>\n"
                             else
                               "#{YsdPluginInvoices.r18n.t.invoices.pdf.payment_method.upcase}:\n"
                             end   
            economic_data << if customer_invoice.expected_payment_date
                               "#{YsdPluginInvoices.r18n.t.invoices.pdf.expected_payment_date.upcase}: <b>#{customer_invoice.expected_payment_date.strftime('%d/%m/%Y')}</b>\n"
                             else
                               "#{YsdPluginInvoices.r18n.t.invoices.pdf.expected_payment_date.upcase}:"
                             end                                

            table_data = []
            table_data << [
                         "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.economic_data.upcase}</b>",
                         "<b>#{YsdPluginInvoices.r18n.t.invoices.pdf.notes.upcase}</b>"]
            table_data << [
                         economic_data,
                         customer_invoice.notes
                        ]                    

            pdf.move_down 10
            pdf.table(table_data, position: :center, width: 560, cell_style: {inline_format: true}) do |t| 
              t.row(0).background_color = 'eeeeee'
              t.row(1).style(height: 40)
              t.column(0).style(:align => :left, size: 10, width: 200) 
              t.column(1).style(:align => :left, size: 10, width: 360)
              t.row(1).style(size: 8)       
              t.row(0).column(0).style(align: :center)
              t.row(0).column(1).style(align: :center)              
            end 

            pdf.move_down 20

            pdf.text YsdPluginInvoices.r18n.t.invoices.pdf.footer, inline_format: true, size:7, align: :left

            #
            # Draft marker
            #
            if customer_invoice.invoice_status == :draft
              pdf.rotate(30, origin: [250, 150]) do
                pdf.draw_text YsdPluginInvoices.r18n.t.invoices_pdf.draft , size: 90, at: [180, 300]
              end  
            end

            return pdf

          end          

        end
      end
    end
  end
end

