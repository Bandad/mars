class QuotationsController < ApplicationController

  before_filter :find_quotation, only: [:show, :edit, :update, :destroy, :issue, :import, :reopen, :convert]

  def import
    @quotation.import(params[:file])
    redirect_to :back, flash: {success: 'Lines were successfully imported'}
  end
  
  def index
    @quotations = Quotation.all

    respond_to do |format|
      format.html 
    end
  end

  def show
    flash[:notice] = params[:warning] if params[:warning]
    # @line = @quotation.quotation_lines.new
    
    respond_to do |format|
      format.html
      format.pdf do
        pdf = SalesQuotePdf.new(@quotation)
        send_data pdf.render, filename: "#{@quotation.code}.pdf",
                              type: "application/pdf",
                              disposition: "inline"
      end
    end
  end

  def new
    @quotation = Quotation.new
    @quotation.code = Quotation.last ? Quotation.last.code.next : 'SQ0001'
    @quotation.customer = Company.find(params[:customer_id])
    # @quotation.customer_id = @customer.id
    @quotation.project_id = params[:project_id]
    @quotation.supplier_id = 2                          # hard coded! To be changed.

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @quotation }
    end
  end

  def edit
    @customer = Company.find(@quotation.customer_id)
  end

  def create
    @quotation = Quotation.new(params[:quotation])

    respond_to do |format|
      if @quotation.save
        @quotation.events.create!(state: 'open', user_id: current_user.id)
        format.html { redirect_to @quotation, notice: 'Quotation was successfully created.' }
        format.json { render json: @quotation, status: :created, location: @quotation }
      else
        format.html { render action: "new" }
        format.json { render json: @quotation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /quotations/1
  # PATCH/PUT /quotations/1.json
  def update
    respond_to do |format|
      if @quotation.update_attributes(params[:quotation])
        format.html { redirect_to @quotation, notice: 'Quotation was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @quotation.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def issue
    respond_to do |format|
      if @quotation.issue(current_user) 
        @quotation.update_attributes(issue_date: Date.today)
        @quotation.create_pdf
        format.html { redirect_to new_email_path params: {type: 'Quotation',
                                                          id: @quotation.id} , 
                                flash: {success: 'Quotation status changed to issued'} }
      else
        format.html { redirect_to @quotation, flash: {error: @quotation.errors.full_messages.join(' ')} }
      end
    end
  end
  
  def reopen
    respond_to do |format|
      if @quotation.reopen(current_user) 
        # @quotation.update_attributes(issue_date: Date.today)
        format.html { redirect_to @quotation, flash: {success: 'Quotation status changed to open'} }
      else
        format.html { redirect_to @quotation, flash: {error: @quotation.errors.full_messages.join(' ')} }
      end
    end
  end

  def convert
    respond_to do |format|
      # create a new sales order based on the quotation and change status of quotation to 'ordered'
      if @quotation.convert(current_user)
        @quotation.clone_as_sales_order
        format.html { redirect_to @quotation.customer, flash: {success: 'New Sales Order created'}}
      else
        format.html { redirect_to @quotation, flash: {error: @quotation.errors.full_messages.join(' ')} }
      end
    end
  end

  def destroy
    @quotation.destroy

    respond_to do |format|
      format.html { redirect_to :back } # destroy link on company show page NOT on quotation show
      format.json { head :no_content }
    end
  end

  private

  def find_quotation
    @quotation = Quotation.find(params[:id]) if params[:id]
  end

end
