# frozen_string_literal: true

require 'test_helper'

class AggregateRepositoryTest < ActiveSupport::TestCase
  setup do
    @repository = RailsSimpleEventSourcing::AggregateRepository.new(Customer)
  end

  test 'builds a new aggregate when aggregate_id is nil' do
    aggregate = @repository.find_or_build(nil)

    assert aggregate.new_record?
    assert_instance_of Customer, aggregate
  end

  test 'builds a new aggregate when aggregate_id is blank' do
    aggregate = @repository.find_or_build('')

    assert aggregate.new_record?
    assert_instance_of Customer, aggregate
  end

  test 'finds an existing aggregate by id' do
    customer = create_customer

    aggregate = @repository.find_or_build(customer.id)

    assert_equal customer.id, aggregate.id
  end

  test 'acquires a FOR UPDATE lock when finding an existing aggregate' do
    customer = create_customer
    queries = []

    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      queries << payload[:sql]
    end

    @repository.find_or_build(customer.id)

    ActiveSupport::Notifications.unsubscribe(subscriber)

    assert queries.any? { |sql| sql.include?('FOR UPDATE') },
           "Expected a FOR UPDATE query, got:\n#{queries.join("\n")}"
  end

  test 'raises RecordNotFound when aggregate does not exist' do
    assert_raises(ActiveRecord::RecordNotFound) do
      @repository.find_or_build(-1)
    end
  end

  test 'saves an aggregate' do
    aggregate = Customer.new(first_name: 'John', last_name: 'Doe', email: 'john@example.com')
    aggregate.enable_write_access!

    @repository.save!(aggregate)

    assert aggregate.persisted?
    assert_equal 'John', aggregate.reload.first_name
  end

  test 'save! raises ReadOnlyRecord without repository' do
    aggregate = Customer.new(first_name: 'John', last_name: 'Doe', email: 'john@example.com')

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      aggregate.save!
    end
  end

  private

  def create_customer
    customer = Customer.new(first_name: 'Jane', last_name: 'Doe', email: "jane_#{SecureRandom.hex(4)}@example.com")
    customer.enable_write_access!
    customer.save!
    customer
  end
end
