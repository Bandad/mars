require 'spec_helper'

describe Event do
  before :each do
    @quotation = create(:quotation)
  end

  it "is valid with a state of 'open'" do
  	event = Event.new(
  		eventable_id: 1,
  		eventable_type: 'Quotation',
  		state: 'open',
  		user_id: 1)
  	expect(event).to be_valid
  end
  it "is not valid with a state of 'fred' for quotation" do
  	event = Event.new(
  		eventable_id: 1,
  		eventable_type: 'Quotation',
  		state: 'fred',
  		user_id: 1)
  	expect(event).to be_invalid
  end

  it "knows what the latest state is" do
 	event = Event.create(
  		eventable_id: @quotation.id,
  		eventable_type: 'Quotation',
  		state: 'cancelled',
  		user_id: 1)
  	expect(Event.with_last_state('cancelled')).to eq [event]
  end

	it "knows what the latest state is" do
		event = Event.create(
			eventable_id: @quotation.id,
			eventable_type: 'Quotation',
			state: 'cancelled',
			user_id: 1)
		expect(Event.with_last_state('open')).to eq []
  end

  it "validates state for purchase orders" do
    event = Event.new(
      eventable_id: 1,
      eventable_type: 'PurchaseOrder',
      state: 'fred',
      user_id: 1)
    expect(event).to be_invalid
  end

  it "validates state for sales orders" do
    event = Event.new(
      eventable_id: 1,
      eventable_type: 'SalesOrder',
      state: 'fred',
      user_id: 1)
    expect(event).to be_invalid
  end
end
