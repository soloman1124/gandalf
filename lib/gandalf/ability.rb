require 'active_support/concern'

module Gandalf
  module Ability
    extend ActiveSupport::Concern

    def can? action, subject = Object
      action = normalise_action(action)
      hit = rules.detect{|rule| rule.relevant? action, subject }
      hit && hit.parity
    end

    def cannot? *args
      !can? *args
    end

    def can *args, &proc
      add_rule true, *args, &proc
    end

    def cannot *args, &proc
      add_rule false, *args, &proc
    end

    def alias_action names, action
      Array.wrap(names).each do |name|
        aliases[name.to_sym] = action
      end
    end

    def unalias_action names
      Array.wrap(names).each do |name|
        aliases.delete name.to_sym
      end
    end

    def rules
      @_rules ||= []
    end

    def aliases
      @_aliases ||= {}
    end

  private

    def add_rule parity, actions, subjects = Object, &proc
      actions = Array.wrap(actions).map{|action| normalise_action(action) }
      rules << Rule.new(parity, actions, subjects, &proc)
    end

    def normalise_action action
      action = action.to_sym
      aliases[action] || action
    end
  end
end