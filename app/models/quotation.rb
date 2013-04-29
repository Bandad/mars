class Quotation < ActiveRecord::Base
  # attr_accessible :address_id, :company_id, :contact_id, :issue_date, :name, :notes, :project_id, :status, :supplier_id, :total
  
  belongs_to :customer, class_name: 'Company'
  belongs_to :supplier, class_name: 'Company'
  belongs_to :project
  belongs_to :address
  belongs_to :contact
  belongs_to :delivery_address, class_name: 'Address'
  
  has_many  :quotation_lines, dependent: :destroy
  accepts_nested_attributes_for :quotation_lines
  has_many :events, as: :eventable
  
  validates :customer_id, :supplier_id, :project_id, :name, presence: true
  
  STATES = %w[open issued cancelled ordered]
  delegate :open?, :issued?, :cancelled?, :ordered?, to: :current_state
  
  def total
    total = quotation_lines.sum(:total)
  end
  
  def import(file)
    CSV.foreach(file.path, headers: true) do |row|
      self.quotation_lines.create(row.to_hash)
    end
  end
  
  def self.open_quotations
    joins(:events).merge Event.with_last_state("open")
  end
  
  def current_state
    (events.last.try(:state) || STATES.first).inquiry
  end
  
  def reopen(user)
    errors.add(:base, "Only issued quotations can be re-opened") if !issued?
    if errors.size == 0
    events.create!(state: "open", user_id: user.id)
    else
      false
    end
  end
  
  def issue(user)
    errors.add(:base, "Only open quotaions may be issued") if !open? 
    errors.add(:base, "There are no lines on this quotation") if quotation_lines.empty?
    if errors.size == 0
      events.create!(state: "issued", user_id: user.id)
    else
      false
    end
  end
  
  def cancel
    events.create!(state: "cancelled", user_id: current_user.id) if open?
  end
  
  def convert
    # if issued then create a sales order and if saved successfully then create event
    events.create!(state: "ordered", user_id: current_user.id) if issued?
  end
end
