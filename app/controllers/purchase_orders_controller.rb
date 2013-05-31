class PurchaseOrdersController < ApplicationController
	before_filter :find_purchase_order, except: [:new, :create, :index ]
	helper_method :sort_column, :sort_direction

	 def import
    if params[:file]
      @purchase_order.import(params[:file])
      redirect_to :back, flash: {success: 'Lines were successfully imported'}
    else
      redirect_to :back, flash: {error: 'You must select a file before import'}
    end
    
  end

	def index
		@purchase_orders = PurchaseOrder.current.joins(:project, :supplier).order(sort_column + " " + sort_direction)
    @purchase_orders = @purchase_orders.search(params[:search])
	end

	def show
    flash[:notice] = params[:warning] if params[:warning]
    
    respond_to do |format|
      format.html
      format.pdf do
        pdf = PurchaseOrderPdf.new(@purchase_order)
        send_data pdf.render, filename: "#{@purchase_order.code}.pdf",
                              type: "application/pdf",
                              disposition: "inline"
      end
    end
  end

	def setup
		@purchase_order = PurchaseOrder.new
		@purchase_order.code = PurchaseOrder.next_code
		@purchase_order.supplier = Company.find(params[:supplier_id]) if params[:supplier_id]
    @purchase_order.project = Project.find(params[:project_id]) if params[:project_id]
    @purchase_order.client = Company.find(params[:client_id]) if params[:client_id]
	end

	def new
		@purchase_order = PurchaseOrder.new(params[:purchase_order])
	end

	def create
		@purchase_order = PurchaseOrder.new(params[:purchase_order])

		respond_to do |format|
			if @purchase_order.save
				@purchase_order.events.create!(state: 'open', user_id: current_user.id)
				format.html {redirect_to @purchase_order, flash: {success: "Purchase Order successfully created"}}
			else
				format.html {render action: 'new' }
			end
		end
	end

	def edit
		
	end

	def select_order_lines
		# find all sales order lines for the same project as current PO
		@lines = @purchase_order.project.sales_order_lines
	end

	def create_order_lines
		sales_order_lines = SalesOrderLine.find(params[:line_ids])
		sales_order_lines.each do |s|
			s.purchase_order_lines << @purchase_order.purchase_order_lines.create(name: s.name,
																																	description: s.description,
																																	quantity: s.quantity)
		end
		redirect_to @purchase_order
	end

	def update
		if @purchase_order.update_attributes(params[:purchase_order])
			redirect_to @purchase_order, flash: {success: "Purchase Order successfully updated"}
		else
			render action: 'edit'
		end
	end

	def issue
		if @purchase_order.issue(current_user)
			@purchase_order.update_attributes(issue_date: Date.today, status: 'open')
			@purchase_order.create_pdf
			redirect_to new_email_path params: {type: 'PurchaseOrder', id: @purchase_order.id }
		else
			redirect_to @purchase_order, flash: {error: @purchase_order.errors.full_messages.join(' ')}
		end
	end

	def reopen
		if @purchase_order.reopen(current_user)
			@purchase_order.update_code
			@purchase_order.update_attributes(status: 'open')
			redirect_to @purchase_order, flash: {success: 'Purchase order status changed to open'}
		else
			redirect_to @purchase_order, flash: {error: @purchase_order.errors.full_messages.join(' ')}
		end
	end

  def cancel
    if @purchase_order.cancel(current_user)
    	@purchase_order.update_attributes(status: 'cancel')
      redirect_to @purchase_order, flash: {success: 'purchase order status changed to cancelled'}
    else
      redirect_to @purchase_order, flash: {error: @purchase_order.errors.full_messages.join(' ')}
    end
  end

  def receipt
    if @purchase_order.receipt(current_user)
    	@purchase_order.update_attributes(status: 'delivered')
      redirect_to @purchase_order, flash: {success: 'purchase order status changed to delivered'}
    else
      redirect_to @purchase_order, flash: {error: @purchase_order.errors.full_messages.join(' ')}
    end
  end

  def paid
    if @purchase_order.paid(current_user)
    	@purchase_order.update_attributes(status: 'paid')
      redirect_to @purchase_order, flash: {success: 'purchase order status changed to paid'} 
    else
      redirect_to @purchase_order, flash: {error: @purchase_order.errors.full_messages.join(' ')}
    end
  end

  def list_emails
    @emails = @purchase_order.emails
    render template: 'emails/index' 
  end

  def list_events
    @events = @purchase_order.events
    render template: 'events/index' 
  end

	private
	def find_purchase_order
		@purchase_order = PurchaseOrder.find(params[:id]) if params[:id]
	end

	 def sort_column
     %w[purchase_orders.code purchase_orders.name projects.code companies.name issue_date due_date total status].include?(params[:sort]) ? params[:sort] : "purchase_orders.code"
   end

   def sort_direction
     %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
   end
end