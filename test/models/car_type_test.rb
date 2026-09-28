require "test_helper"

class CarTypeTest < Minitest::Test
  def test_lookup_is_case_insensitive
    assert_same CarType.fetch("Sedan"), CarType.fetch(:sedan)
  end

  def test_unknown_type_is_a_validation_error
    assert_raises(Errors::ValidationError) { CarType.fetch("suv") }
    assert_raises(Errors::ValidationError) { CarType.fetch(nil) }
  end

  def test_upgrade_chain
    assert_equal %w[hatchback sedan], CarType.fetch(:hatchback).upgrade_chain.map(&:to_s)
    assert_equal %w[sedan], CarType.fetch(:sedan).upgrade_chain.map(&:to_s)
  end
end
