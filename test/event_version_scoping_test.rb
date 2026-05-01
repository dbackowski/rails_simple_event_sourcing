# frozen_string_literal: true

require 'test_helper'

class EventVersionScopingTest < ActiveSupport::TestCase
  test 'version is calculated per aggregate type, not across types sharing an aggregate_id' do
    # Force the next Account to share its primary key with the next Customer.
    customer_event = Customer::Events::CustomerCreated.create!(
      first_name: 'John',
      last_name: 'Doe',
      email: "john_#{SecureRandom.hex(4)}@example.com",
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    )

    Customer::Events::CustomerUpdated.create!(
      aggregate_id: customer_event.aggregate_id,
      first_name: 'Jane',
      last_name: 'Smith',
      email: "jane_#{SecureRandom.hex(4)}@example.com",
      updated_at: Time.zone.now
    )
    # Customer now has events at versions 1 and 2.

    Account.connection.execute(
      "SELECT setval('accounts_id_seq', #{customer_event.aggregate_id.to_i}, false)"
    )
    account_event = Account::Events::AccountCreated.create!(
      name: 'Acme',
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    )
    assert_equal customer_event.aggregate_id, account_event.aggregate_id,
                 'precondition: customer and account must share the same aggregate_id'

    update_event = Account::Events::AccountUpdated.create!(
      aggregate_id: account_event.aggregate_id,
      name: 'Acme Inc.',
      updated_at: Time.zone.now
    )

    assert_equal 2, update_event.version,
                 "second event for the Account aggregate must be version 2 — Customer's events on the same id must not bump the Account's version stream"
  end
end
