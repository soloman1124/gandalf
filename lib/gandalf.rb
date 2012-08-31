require "gandalf/version"
require 'active_support/concern'

module Gandalf
  extend ActiveSupport::Concern

  class AuthorizationRequired < Exception; end
  YouShallNotPass = AuthorizationRequired

  included do
    helper_method :current_user, :signed_in?, :signed_out?
    hide_action *(Gandalf.instance_methods)
  end

  module ClassMethods

    @@gandalf_retrieve_user = nil
    def gandalf_retrieve_user method_name = nil, &block
      if block_given?
        raise ArgumentError, "Block must accept 1 argument" \
          unless block.arity == 1 || block.arity == -1

        @@gandalf_retrieve_user = block
      elsif !method_name.nil?
        @@gandalf_retrieve_user = method_name
      else
        @@gandalf_retrieve_user
      end
    end

    @@gandalf_persist_user = nil
    def gandalf_persist_user method_name = nil, &block
      if block_given?
        raise ArgumentError, "Block must accept 1 or 2 arguments" \
          unless block.arity == 1 || block.arity == 2 || block.arity == -1

        @@gandalf_persist_user = block
      elsif !method_name.nil?
        @@gandalf_persist_user = method_name
      else
        @@gandalf_persist_user
      end
    end

  end

  def current_user
    @current_user ||= retrieve_user
  end

  def current_user= user
    @current_user = user
  end

  def sign_in user
    persist_user user
    self.current_user = user
  end

  def signed_in?
    !!current_user
  end

  def sign_out
    persist_user nil
    self.current_user = nil
  end

  def signed_out?
    !signed_in?
  end

  def redirect_back_or default
    redirect_to return_to || default
    clear_return_to
  end

  def store_location
    session[:return_to] = request.fullpath if request.get?
  end

  def clear_return_to
    session.delete :return_to
  end

  def return_to
    session[:return_to] || params[:return_to]
  end

  def deny_access
    raise YouShallNotPass, """
This message should be rescued in your controller.

<pre>
rescue_from 'Gandalf::AuthorizationRequired' do |exception|
  if signed_in?
    redirect_to root_path
  else
    redirect_to sign_in_path
  end
end
</pre>
"""

  end

  def authorize
    deny_access unless signed_in?
  end

  # CSRF protection in Rails >= 3.0.4
  # http://weblog.rubyonrails.org/2011/2/8/csrf-protection-bypass-in-ruby-on-rails
  def handle_unverified_request
    super
    sign_out
  end

private

  def retrieve_user
    case gandalf_retrieve_user
    when Proc
      gandalf_retrieve_user.call(self)
    when Symbol, String
      send(gandalf_retrieve_user)
    else
      raise NotImplementedError, """
Gandalf doesn't know how to retrieve a user.

<pre>
gandalf_retrieve_user do |controller|
  User.find controller.cookie[:user_id]
end
</pre>
"""
    end
  end

  def persist_user user
    case gandalf_persist_user
    when Proc
      if gandalf_persist_user.arity == 1
        gandalf_persist_user.call(user)
      else
        gandalf_persist_user.call(self, user)
      end
    when Symbol, String
      send(gandalf_persist_user, user)
    else
      raise NotImplementedError, """
No way for Gandalf to persist the user.

<pre>
gandalf_persist_user do |controller, user|
  if user
    controller.session[:user_id] = user.id
  else
    controller.session.delete :user_id
  end
end
</pre>
"""
    end
  end

  def gandalf_retrieve_user
    self.class.gandalf_retrieve_user
  end

  def gandalf_persist_user
    self.class.gandalf_persist_user
  end

end
