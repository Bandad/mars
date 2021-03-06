class SalesOrderPdf < Prawn::Document
  def initialize(sales_order)
    super(bottom_margin: 50)
    @sales_order = sales_order
    
    define_grid(columns: 3, rows: 6, gutter: 0)
    #grid.show_all
    font_size 10
    
    grid([0,1],[0,2]).bounding_box do
      logo
    end
    
    grid([0,0],[0,1]).bounding_box do
      sales_order_heading
    end

    grid([1,0],[1,1]).bounding_box do
      address_box
    end

    order_number_and_date
    order_comment
    order_table
    order_total
    fold_mark
    our_address
    sales_order_page_number
    sales_order_number
  end
  
  def fold_mark
    repeat([1]) do         # only on first page
      transparent(0.5){stroke_horizontal_line -20, -10, at: 464 }
    end
  end
  
  def address_box
    if @sales_order.address
    text_box "#{@sales_order.customer.name}
              #{@sales_order.address.body}
              #{@sales_order.address.post_code}",
              size: 10 
    else
      text_box "MISSING AN ADDRESS!"
    end
  end
  
  def sales_order_heading
    move_down 50
    text "Sales Order",
          size: 20, 
          style: :bold
  end
  
  def logo
    if @sales_order.supplier.name.include? "Roger"
      image "#{Rails.root}/app/assets/images/RBDC_logo.png",
      postion: :right,
      fit: [350,50]
    else
      image "#{Rails.root}/app/assets/images/blue_square_logo.png",
      position: :right,
      vposition: :center,
      fit: [70,70]
    end
  end
  
  def order_number_and_date
      date = @sales_order.issue_date ? @sales_order.issue_date.strftime("%d %B %Y") : "NOT ISSUED"
      data = [["Ref.:","#{@sales_order.code}","Date", date]]
      table(data) do
        cells.borders = []
        columns(2).align = :right
        columns(3).align = :right
        columns(0).width = 80
        columns(1).width = 250
        columns(2).width = 110
        columns(3).width = 100
      end
    end
    
    def order_comment
      move_down 15
      text "#{@sales_order.name}\n", style: :bold, size: 14
      move_down 6
      text "#{@sales_order.description}", style: :italic
    end
     
    def order_table
      move_down 15
      table order_lines do
        self.width = 540
        row(0).font_style = :bold
        # columns(0).align = :right
        columns(3).align = :right
        columns(4).align = :right
        columns(5).align = :right
        self.header = true
        cells.borders = []
        row(0).borders = [:bottom]
        row(-1).borders = [:bottom]
        row(0).border_width = 0.5
        row(-1).border_width = 0.5
        columns(0).width = 15       # row number
        columns(0).size = 9
        columns(1).width = 75       # item (name)
        columns(1).size = 9
        row(0).size = 10
        # columns(2).width = 240      # specification (description)
        columns(3).width = 55       # quantity
        columns(4).width = 75       # unit_price
        columns(5).width = 75       # total
      end
    end
    
    def order_lines
      output = []
      rowno = 0
      cat = ""
      output << ["","Item", "Specification", "Quantity", "Unit Price","Total"]
      @sales_order.sales_order_lines.map do |line|
        if cat == line.category
          output << ["#{'%02i' % rowno += 1}", line.name, line.description, line.quantity, price(line.unit_price), price(line.total)]
        else
          cat = line.category
          output << [{content: line.category, colspan: 3, font_style: :bold},"","",""]
          output << ["#{'%02i' % rowno += 1}", line.name, line.description, line.quantity, price(line.unit_price), price(line.total)]
        end
      end
      output
    end
    
    def order_total
      move_down 15
      data = [["","Total (excluding VAT):", "#{price(@sales_order.total)}"]]
      table(data) do
        cells.borders = []
        columns(1).align = :right
        columns(2).align = :right
        columns(0).width = 340
        columns(1).width = 120
        columns(2).width = 80
      end
    end
    
    def price(num)
      helpers.number_to_currency(num)
    end
    
    def our_address
      if @sales_order.supplier.addresses.first
        addr = "#{@sales_order.supplier.addresses.first.body.gsub(/\n/,', ')}, #{@sales_order.supplier.addresses.first.post_code}"
        if @sales_order.supplier.name.include? "Elderberry"
          addr = addr + "\nRegistered No. 2993752 VAT Reg No. 619 9162 14"
        end
      else
        addr = "address missing"
      end

      repeat(:all) do
        canvas do
          move_cursor_to 30
          line_width 0.1
          transparent(0.5){
          stroke_horizontal_rule}
          text_box addr, at: [70,20], align: :center, size: 8, width: 400
        end
      end
    end
    
    def sales_order_page_number
      string = "page <page> of <total>"
      options = { at: [500, 20],
                width: 70,
                align: :right,
                size: 8,
                start_count: 1
                }
      canvas do
        number_pages string, options
      end
    end
    
    def sales_order_number
      string = @sales_order.code
      options = { at: [30, 20],
                width: 40,
                align: :left,
                size: 8
                }
      repeat(:all) do
        canvas do
          text_box string, options
        end
      end
    end
    
    def helpers
      ActionController::Base.helpers
    end
end