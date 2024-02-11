require 'test_helper'

class CustomersControllerTest < ActionDispatch::IntegrationTest
  test "should create customer" do
    assert_equal 0, Customer.count
    assert_equal 0, RailsSimpleEventSourcing::Event.count

    assert_changes -> { Customer.count } do
      assert_changes -> { RailsSimpleEventSourcing::Event.count } do
        post customers_url, params: { first_name: 'John', last_name: 'Doe' }, headers: { 'HTTP_REFERER' => 'example.com' }
      end
    end

    customer_event = RailsSimpleEventSourcing::Event.find_by(event_type: "Customer::Events::CustomerCreated")
    customer = Customer.last

    assert_equal 'John', customer_event.payload['first_name']
    assert_equal 'Doe', customer_event.payload['last_name']
    assert_not_empty customer_event.payload['created_at']
    assert_not_empty customer_event.payload['updated_at']
    assert_not_empty customer_event.metadata['request_id']
    assert_equal '127.0.0.1', customer_event.metadata['request_ip']
    assert_not_empty customer_event.metadata['request_params']
    assert_equal 'example.com', customer_event.metadata['request_referer']

    assert_equal customer.first_name, customer_event.payload['first_name']
    assert_equal customer.last_name, customer_event.payload['last_name']
    assert_in_delta customer.created_at, customer_event.payload['created_at'].to_datetime
    assert_in_delta customer.updated_at, customer_event.payload['updated_at'].to_datetime

    assert_equal 1, customer.events.count
    assert_equal customer.events.last, customer_event
  end

  test 'should update customer' do
    cmd = Customer::Commands::Create.new(
      first_name: 'John',
      last_name: 'Doe'
    )
    handler = RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    assert_no_changes -> { Customer.count } do
      assert_changes -> { RailsSimpleEventSourcing::Event.count } do
        put customer_url(Customer.last.id), params: { first_name: 'John', last_name: 'Rambo' }, headers: { 'HTTP_REFERER' => 'example.com' }
      end
    end

    customer_event = RailsSimpleEventSourcing::Event.find_by(event_type: "Customer::Events::CustomerUpdated")
    customer = Customer.last

    assert_equal 'John', customer_event.payload['first_name']
    assert_equal 'Rambo', customer_event.payload['last_name']
    assert_not_empty customer_event.payload['updated_at']
    assert_not_empty customer_event.metadata['request_id']
    assert_equal '127.0.0.1', customer_event.metadata['request_ip']
    assert_not_empty customer_event.metadata['request_params']
    assert_equal 'example.com', customer_event.metadata['request_referer']

    assert_equal customer.first_name, customer_event.payload['first_name']
    assert_equal customer.last_name, customer_event.payload['last_name']
    assert_in_delta customer.updated_at, customer_event.payload['updated_at'].to_datetime

    assert_equal 2, customer.events.count
    assert_equal customer.events.last, customer_event
  end
end
