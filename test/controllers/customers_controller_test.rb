# frozen_string_literal: true

require 'test_helper'

class CustomersControllerTest < ActionDispatch::IntegrationTest
  test 'should create customer' do
    assert_equal 0, Customer.count
    assert_equal 0, RailsSimpleEventSourcing::Event.count

    assert_changes -> { Customer.count } do
      assert_changes -> { RailsSimpleEventSourcing::Event.count } do
        post customers_url, params: { first_name: 'John', last_name: 'Doe', email: 'jdoe@example.com' },
                            headers: { 'HTTP_REFERER' => 'example.com' }
      end
    end

    response_body = response.parsed_body

    assert_equal 200, response.status
    assert_not_nil response_body['id']
    assert_equal 'John', response_body['first_name']
    assert_equal 'Doe', response_body['last_name']
    assert_equal 'jdoe@example.com', response_body['email']
    assert_nil response_body['deleted_at']
    assert_not_empty response_body['created_at']
    assert_not_empty response_body['updated_at']

    customer_event = RailsSimpleEventSourcing::Event.find_by(event_type: 'Customer::Events::CustomerCreated')
    customer = Customer.last

    assert_equal 'John', customer_event.payload['first_name']
    assert_equal 'Doe', customer_event.payload['last_name']
    assert_equal 'jdoe@example.com', customer_event.payload['email']
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

  test 'should not create another customer with the same email' do
    cmd = Customer::Commands::Create.new(
      first_name: 'John',
      last_name: 'Doe',
      email: 'jdoe@example.com'
    )

    RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    assert_no_changes -> { Customer.count } do
      assert_changes -> { RailsSimpleEventSourcing::Event.count } do
        post customers_url, params: { first_name: 'John', last_name: 'Doe', email: 'jdoe@example.com' },
                            headers: { 'HTTP_REFERER' => 'example.com' }
      end
    end

    customer_event = RailsSimpleEventSourcing::Event.find_by(event_type: 'Customer::Events::CustomerEmailTaken')

    response_body = response.parsed_body

    assert_equal 422, response.status
    assert_equal ['already taken'], response_body['errors']['email']
    assert_equal 'John', customer_event.payload['first_name']
    assert_equal 'Doe', customer_event.payload['last_name']
    assert_equal 'jdoe@example.com', customer_event.payload['email']
    assert_not_empty customer_event.metadata['request_id']
    assert_equal '127.0.0.1', customer_event.metadata['request_ip']
    assert_not_empty customer_event.metadata['request_params']
    assert_equal 'example.com', customer_event.metadata['request_referer']
  end

  test 'should update customer' do
    cmd = Customer::Commands::Create.new(
      first_name: 'John',
      last_name: 'Doe',
      email: 'jdoe@example.com'
    )
    RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    assert_no_changes -> { Customer.count } do
      assert_changes -> { RailsSimpleEventSourcing::Event.count } do
        put customer_url(Customer.last.id), params: { first_name: 'John', last_name: 'Rambo' },
                                            headers: { 'HTTP_REFERER' => 'example.com' }
      end
    end

    response_body = response.parsed_body

    assert_equal 200, response.status
    assert_not_nil response_body['id']
    assert_equal 'John', response_body['first_name']
    assert_equal 'Rambo', response_body['last_name']
    assert_nil response_body['deleted_at']
    assert_not_empty response_body['created_at']
    assert_not_empty response_body['updated_at']

    customer_event = RailsSimpleEventSourcing::Event.find_by(event_type: 'Customer::Events::CustomerUpdated')
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

  test 'should delete customer' do
    cmd = Customer::Commands::Create.new(
      first_name: 'John',
      last_name: 'Doe',
      email: 'jdoe@example.com'
    )
    RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    assert_no_changes -> { Customer.count } do
      assert_changes -> { RailsSimpleEventSourcing::Event.count } do
        delete customer_url(Customer.last.id), headers: { 'HTTP_REFERER' => 'example.com' }
      end
    end

    response_body = response.parsed_body

    assert_equal 204, response.status
    assert_empty response_body

    customer_event = RailsSimpleEventSourcing::Event.find_by(event_type: 'Customer::Events::CustomerDeleted')
    customer = Customer.last

    assert_in_delta customer.deleted_at, customer_event.payload['deleted_at'].to_datetime
    assert_not_empty customer_event.metadata['request_id']
    assert_equal '127.0.0.1', customer_event.metadata['request_ip']
    assert_not_empty customer_event.metadata['request_params']
    assert_equal 'example.com', customer_event.metadata['request_referer']

    assert_equal 2, customer.events.count
    assert_equal customer.events.last, customer_event
  end

  test 'should not allow to modify customer without applying the event' do
    cmd = Customer::Commands::Create.new(
      first_name: 'John',
      last_name: 'Doe',
      email: 'jdoe@example.com'
    )
    RailsSimpleEventSourcing::CommandHandler.new(cmd).call

    customer = Customer.last

    assert_raise ActiveRecord::ReadOnlyRecord do
      customer.update!(last_name: 'Rambo')
    end

    assert_raise ActiveRecord::ReadOnlyRecord do
      customer.destroy!
    end
  end

  test 'should not allow to create a new customer without applying the event' do
    assert_raise ActiveRecord::ReadOnlyRecord do
      Customer.create!(
        first_name: 'John',
        last_name: 'Doe'
      )
    end
  end
end
