require 'test_helper'

class AbilityTest < ActionController::TestCase
  class TestAbility
    include Gandalf::Ability
  end

  test "#can should add a positive rule" do
    ability = TestAbility.new
    assert_empty ability.rules

    ability.can :test
    refute_empty ability.rules
  end

  test "#cannot should add a negative rule" do
    ability = TestAbility.new
    assert_empty ability.rules

    ability.cannot :test
    refute_empty ability.rules
  end

  test "#can? should return true when action hits" do
    ability = TestAbility.new
    ability.can :test

    assert ability.can?(:test)
  end

  test "#can? should return false when action doesn't hits" do
    ability = TestAbility.new
    refute ability.can?(:test)
  end

  test "#can? should return false when action hit is negative" do
    ability = TestAbility.new
    ability.cannot :test

    refute ability.can?(:test)
  end

  test "#cannot? should return true when action hits" do
    ability = TestAbility.new
    ability.cannot :test

    assert ability.cannot?(:test)
  end

  test "#cannot? should return true when action doesn't hits" do
    ability = TestAbility.new
    assert ability.cannot?(:test)
  end

  test "#cannot? should return false when hit is positive" do
    ability = TestAbility.new
    ability.can :test

    refute ability.cannot?(:test)
  end

  test "#alias_action should add alias for action specified" do
    ability = TestAbility.new
    assert_empty ability.aliases

    ability.alias_action :foobar, :test
    refute_empty ability.aliases
  end

  test "#unalias_action should remove the specified alias" do
    ability = TestAbility.new
    ability.aliases[:foobar] = :test

    ability.unalias_action :foobar
    assert_empty ability.aliases
  end

  test "#can? should return true when alias hits" do
    ability = TestAbility.new
    ability.can :test
    ability.alias_action :foobar, :test

    assert ability.can?(:foobar)
  end

  test "#can should add positive using aliased action" do
    ability = TestAbility.new
    ability.alias_action :foobar, :test
    ability.can :foobar

    assert ability.can?(:foobar)
  end
end