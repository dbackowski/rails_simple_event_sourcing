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

    assert_equal %w[id first_name last_name email deleted_at created_at updated_at], response_body.keys
    assert_equal 200, response.status
    assert_not_nil response_body['id']
    assert_equal 'John', response_body['first_name']
    assert_equal 'Doe', response_body['last_name']
    assert_equal 'jdoe@example.com', response_body['email']
    assert_nil response_body['deleted_at']
    assert_not_empty response_body['created_at']
    assert_not_empty response_body['updated_at']

    customer_event = RailsSimpleEventSourcing::Event.find_by(type: 'Customer::Events::CustomerCreated')
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

    RailsSimpleEventSourcing.dispatch(cmd)

    assert_no_changes -> { Customer.count } do
      assert_changes -> { RailsSimpleEventSourcing::Event.count } do
        post customers_url, params: { first_name: 'John', last_name: 'Doe', email: 'jdoe@example.com' },
                            headers: { 'HTTP_REFERER' => 'example.com' }
      end
    end

    customer_event = RailsSimpleEventSourcing::Event.find_by(type: 'Customer::Events::CustomerEmailTaken')

    response_body = response.parsed_body

    assert_equal 422, response.status
    assert_equal ['already taken'], response_body['errors']['email']
    assert_equal 'John', customer_event.payload['first_name']
    assert_equal 'Doe', customer_event.payload['last_name']
    assert_equal 'jdoe@example.com', customer_event.payload['email']
    assert_nil customer_event.version
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
    RailsSimpleEventSourcing.dispatch(cmd)

    assert_no_changes -> { Customer.count } do
      assert_changes -> { RailsSimpleEventSourcing::Event.count }, from: 1, to: 2 do
        put customer_url(Customer.last.id),
            params: { first_name: 'John', last_name: 'Rambo', email: 'jrambo@example.com' },
            headers: { 'HTTP_REFERER' => 'example.com' }
      end
    end

    response_body = response.parsed_body

    assert_equal %w[email last_name created_at first_name updated_at id deleted_at].to_set, response_body.keys.to_set
    assert_equal 200, response.status
    assert_not_nil response_body['id']
    assert_equal 'John', response_body['first_name']
    assert_equal 'Rambo', response_body['last_name']
    assert_equal 'jrambo@example.com', response_body['email']
    assert_nil response_body['deleted_at']
    assert_not_empty response_body['created_at']
    assert_not_empty response_body['updated_at']

    customer_event = RailsSimpleEventSourcing::Event.find_by(type: 'Customer::Events::CustomerUpdated')
    customer = Customer.last

    # To checked that all events were applied correctly, we change the email into a different value directy in DB
    Customer.update_all(email: 'jdoe@example.com') # rubocop:disable Rails/SkipsModelValidations

    assert_equal 'John', customer_event.payload['first_name']
    assert_equal 'Rambo', customer_event.payload['last_name']
    assert_equal 'jrambo@example.com', customer_event.payload['email']
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

    assert_no_changes -> { Customer.count } do
      assert_changes -> { RailsSimpleEventSourcing::Event.count }, from: 2, to: 3 do
        put customer_url(Customer.last.id), params: { first_name: 'Jane', last_name: 'Doe' },
                                            headers: { 'HTTP_REFERER' => 'example.com' }
      end
    end

    response_body = response.parsed_body

    assert_equal 200, response.status
    assert_not_nil response_body['id']
    assert_equal 'Jane', response_body['first_name']
    assert_equal 'Doe', response_body['last_name']
    assert_equal 'jrambo@example.com', response_body['email']
    assert_nil response_body['deleted_at']
    assert_not_empty response_body['created_at']
    assert_not_empty response_body['updated_at']
  end

  test 'should not update customer when validation fails' do
    cmd = Customer::Commands::Create.new(
      first_name: 'John',
      last_name: 'Doe',
      email: 'jdoe@example.com'
    )
    RailsSimpleEventSourcing.dispatch(cmd)

    assert_no_changes -> { Customer.count } do
      assert_no_changes -> { RailsSimpleEventSourcing::Event.count } do
        put customer_url(Customer.last.id),
            params: { first_name: 'John' },
            headers: { 'HTTP_REFERER' => 'example.com' }
      end
    end

    response_body = response.parsed_body

    assert_equal 422, response.status

    assert_equal 1, response_body['errors'].keys.size
    assert_equal 'can\'t be blank', response_body['errors']['last_name'][0]
  end

  test 'should delete customer' do
    cmd = Customer::Commands::Create.new(
      first_name: 'John',
      last_name: 'Doe',
      email: 'jdoe@example.com'
    )
    RailsSimpleEventSourcing.dispatch(cmd)

    assert_no_changes -> { Customer.count } do
      assert_changes -> { RailsSimpleEventSourcing::Event.count } do
        delete customer_url(Customer.last.id), headers: { 'HTTP_REFERER' => 'example.com' }
      end
    end

    response_body = response.parsed_body

    assert_equal 204, response.status
    assert_empty response_body

    customer_event = RailsSimpleEventSourcing::Event.find_by(type: 'Customer::Events::CustomerDeleted')
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
    RailsSimpleEventSourcing.dispatch(cmd)

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

  test 'aggregate instance returned from command handler is read-only after event creation' do
    cmd = Customer::Commands::Create.new(
      first_name: 'John',
      last_name: 'Doe',
      email: 'jdoe@example.com'
    )
    result = RailsSimpleEventSourcing.dispatch(cmd)
    customer = result.data

    assert_raise ActiveRecord::ReadOnlyRecord do
      customer.update!(last_name: 'Hacked')
    end
  end

  test 'aggregate is correctly rebuilt from upcasted v1 events' do
    post customers_url,
         params: { first_name: 'John', last_name: 'Doe', email: 'jdoe@example.com' },
         headers: { 'HTTP_REFERER' => 'example.com' }

    event = RailsSimpleEventSourcing::Event.find_by(type: 'Customer::Events::CustomerCreated')
    customer = Customer.last

    # Simulate a legacy v1 event with "name" instead of first_name/last_name
    v1_payload = {
      name: 'John Doe',
      email: 'jdoe@example.com',
      created_at: customer.created_at.iso8601,
      updated_at: customer.updated_at.iso8601
    }.to_json

    event.class.where(id: event.id).update_all(schema_version: 1) # rubocop:disable Rails/SkipsModelValidations
    RailsSimpleEventSourcing::Event
      .where(id: event.id)
      .update_all(Arel.sql("payload = '#{v1_payload}'::jsonb")) # rubocop:disable Rails/SkipsModelValidations

    # Set different values directly in DB to ensure replay overwrites them
    Customer.where(id: customer.id).update_all(first_name: 'Wrong', last_name: 'Name') # rubocop:disable Rails/SkipsModelValidations

    # Delete the customer — this triggers a full replay including the v1 event
    # The delete event only sets deleted_at, so first_name/last_name come entirely from the upcasted v1 event
    delete customer_url(customer.id), headers: { 'HTTP_REFERER' => 'example.com' }

    assert_equal 204, response.status

    customer.reload
    assert_equal 'John', customer.first_name
    assert_equal 'Doe', customer.last_name
    assert_not_nil customer.deleted_at
  end

  test 'event instance is read-only after creation' do
    event = Customer::Events::CustomerCreated.create!(
      first_name: 'John',
      last_name: 'Doe',
      email: 'jdoe@example.com',
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    )

    assert_raise ActiveRecord::ReadOnlyRecord do
      event.update!(payload: { hacked: true })
    end
  end
end
