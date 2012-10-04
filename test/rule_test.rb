require 'test_helper'

class RuleTest < ActionController::TestCase
  test "#relevant? should return false when action doesn't match" do
    rule = Gandalf::Rule.new true, :read, Object
    refute rule.relevant?(:update, Object)
  end

  test "#relevant? should return false when subject doesn't match" do
    rule = Gandalf::Rule.new true, :read, Object
    refute rule.relevant?(:read, nil)
  end

  test "#relevant? should return true when action and subject match" do
    rule = Gandalf::Rule.new true, :read, Object
    assert rule.relevant?(:read, Object)
  end

  test "#relevant? should return true when action (being :manage) and subject match" do
    rule = Gandalf::Rule.new true, :manage, Object
    assert rule.relevant?(:read, Object)
  end

  test "#relevant? should return true when action and subject (being :all) match" do
    rule = Gandalf::Rule.new true, :read, :all
    assert rule.relevant?(:read, Object)
  end

  test "#relevant? should return true when action and subject (being an object) match" do
    rule = Gandalf::Rule.new true, :manage, Object
    assert rule.relevant?(:read, Object.new)
  end

  test "#relevant? should return true when action and subject match with proc" do
    rule = Gandalf::Rule.new(true, :read, Object) { true }
    assert rule.relevant?(:read, Object)
  end

  test "#relevant? should return false when action and subject match with proc" do
    rule = Gandalf::Rule.new(true, :read, Object) { false }
    refute rule.relevant?(:read, Object)
  end

  test "#relevant? should pass action and subject to proc" do
    ok = false
    rule = Gandalf::Rule.new(true, :read, Object) do |action, subject|
      ok = action == :read && subject == Object
    end
    rule.relevant? :read, Object

    assert ok
  end
end