class SalesOrdersController < ApplicationController
	before_filter :find_sales_order, except: [:new, :create ]#[:show, :edit, :update, :destroy, :issue, :reopen]

  def show
    flash[:notice] = params[:warning] if params[:warning]
    
    respond_to do |format|
      format.html
      format.pdf do
        pdf = SalesOrderPdf.new(@sales_order)
        send_data pdf.render, filename: "#{@sales_order.code}.pdf",
                              type: "application/pdf",
                              disposition: "inline"
      end
    end
  end

	def new
	@sales_order = SalesOrder.new
    @sales_order.code = SalesOrder.next_code
    @sales_order.customer = Company.find(params[:customer_id])
    # @sales_order.customer_id = @customer.id
    @sales_order.project_id = params[:project_id]
    @sales_order.supplier_id = 2                          # hard coded! To be changed.

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @sales_order }	
     end	
	end	

  def create
    @sales_order = SalesOrder.new(params[:sales_order])

    respond_to do |format|
      if @sales_order.save
        @sales_order.events.create!(state: 'open', user_id: current_user.id)
        format.html { redirect_to @sales_order, notice: 'Sales Order was successfully created.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  def edit
    @customer = Company.find(@sales_order.customer.id)
  end

  def update
    respond_to do |format|
      if @sales_order.update_attributes(params[:sales_order])
        format.html {redirect_to @sales_order, flash: {success: 'Sales Order successfully updated'}}
      else
        render action: 'edit'
      end
    end
  end

  def issue
    respond_to do |format|
      if @sales_order.issue(current_user)
        @sales_order.update_attributes(issue_date: Date.today)
        @sales_order.create_pdf
        format.html { redirect_to new_email_path params: {type: 'SalesOrder', id: @sales_order.id},
                        flash: {success: 'Quotation status changed to issued'}}
      else
        format.html {redirect_to @sales_order, flash: {error: @sales_order.errors.full_messages.join(' ')} }
      end
    end
  end

  def reopen
    # create event to 'revise' existing
    # clone to a new copy with revision number
    # create event to 'open' new record unless this is automatic?
    # redirect to new sales order
    respond_to do |format|
      if @sales_order.reopen(current_user)
        @sales_order.update_code
        format.html { redirect_to @sales_order, flash: {success: 'Sales order status changed to open'}}
      else
        format.html { redirect_to @sales_order, flash: {error: @sales_order.errors.full_messages.join(' ')}}
      end
    end
  end

  def accept
    respond_to do |format|
      if @sales_order.accept(current_user)
        format.html { redirect_to @sales_order, flash: {success: 'Sales order status changed to accepted'} }
      else
        format.html { redirect_to @sales_order, flash: {error: @sales_order.errors.full_messages.join(' ')}}
      end
    end
  end

  def cancel
    respond_to do |format|
      if @sales_order.cancel(current_user)
        format.html { redirect_to @sales_order, flash: {success: 'Sales order status changed to cancelled'} }
      else
        format.html { redirect_to @sales_order, flash: {error: @sales_order.errors.full_messages.join(' ')}}
      end
    end
  end

  def invoice
    respond_to do |format|
      if @sales_order.invoice(current_user)
        format.html { redirect_to @sales_order, flash: {success: 'Sales order status changed to invoiced'} }
      else
        format.html { redirect_to @sales_order, flash: {error: @sales_order.errors.full_messages.join(' ')}}
      end
    end
  end

    def paid
    respond_to do |format|
      if @sales_order.paid(current_user)
        format.html { redirect_to @sales_order, flash: {success: 'Sales order status changed to paid'} }
      else
        format.html { redirect_to @sales_order, flash: {error: @sales_order.errors.full_messages.join(' ')}}
      end
    end
  end

	private
	def find_sales_order
		@sales_order = SalesOrder.find(params[:id]) if params[:id]
	end
end