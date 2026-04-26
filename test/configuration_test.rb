# frozen_string_literal: true

require 'test_helper'

class ConfigurationTest < ActiveSupport::TestCase
  setup do
    @original_config = RailsSimpleEventSourcing.instance_variable_get(:@config)
    RailsSimpleEventSourcing.instance_variable_set(:@config, nil)
  end

  teardown do
    RailsSimpleEventSourcing.instance_variable_set(:@config, @original_config)
  end

  test 'has default use_naming_convention_fallback of true' do
    assert_equal true, RailsSimpleEventSourcing.config.use_naming_convention_fallback
  end

  test 'has default events_per_page of 25' do
    assert_equal 25, RailsSimpleEventSourcing.config.events_per_page
  end

  test 'configure yields config block' do
    RailsSimpleEventSourcing.configure do |config|
      config.events_per_page = 50
      config.use_naming_convention_fallback = false
    end

    assert_equal 50, RailsSimpleEventSourcing.config.events_per_page
    assert_equal false, RailsSimpleEventSourcing.config.use_naming_convention_fallback
  end

  test 'config returns same instance' do
    config1 = RailsSimpleEventSourcing.config
    config2 = RailsSimpleEventSourcing.config

    assert_same config1, config2
  end

  test 'configure returns config' do
    result = RailsSimpleEventSourcing.configure do |config|
      config.events_per_page = 10
    end

    assert_instance_of RailsSimpleEventSourcing::Configuration, result
  end

  test 'has default snapshot_interval of nil' do
    assert_nil RailsSimpleEventSourcing.config.snapshot_interval
  end

  test 'snapshot_interval accepts a positive integer' do
    RailsSimpleEventSourcing.config.snapshot_interval = 10
    assert_equal 10, RailsSimpleEventSourcing.config.snapshot_interval
  end

  test 'snapshot_interval accepts nil' do
    RailsSimpleEventSourcing.config.snapshot_interval = 5
    RailsSimpleEventSourcing.config.snapshot_interval = nil
    assert_nil RailsSimpleEventSourcing.config.snapshot_interval
  end

  test 'snapshot_interval rejects zero' do
    assert_raises(ArgumentError) do
      RailsSimpleEventSourcing.config.snapshot_interval = 0
    end
  end

  test 'snapshot_interval rejects negative integers' do
    assert_raises(ArgumentError) do
      RailsSimpleEventSourcing.config.snapshot_interval = -1
    end
  end

  test 'snapshot_interval rejects non-integers' do
    assert_raises(ArgumentError) do
      RailsSimpleEventSourcing.config.snapshot_interval = 1.5
    end

    assert_raises(ArgumentError) do
      RailsSimpleEventSourcing.config.snapshot_interval = '10'
    end
  end
end
