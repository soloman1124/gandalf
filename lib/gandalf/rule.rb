module Gandalf
  class Rule
    attr_reader :parity, :actions, :subjects, :proc

    def initialize parity, action, subject, &proc
      @parity = parity
      @actions = Array.wrap action
      @subjects = Array.wrap subject
      @proc = proc
    end

    def relevant? action, subject
      action = action.to_sym
      match_subject?(subject) && match_action?(action) && match_block?(action, subject)
    end

  private

    def match_subject? subject
      subjects.include?(:all) || subjects.include?(subject) || match_class?(subject)
    end

    def match_class? subject
      klass = subject.is_a?(Class) ? subject : subject.class
      subjects.select{|sub| sub.is_a? Class }.include? klass
    end

    def match_action? action
      actions.include?(:manage) || actions.include?(action)
    end

    def match_block? action, subject
      !proc || proc.call(action, subject)
    end
  end
end