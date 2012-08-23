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

    @@user_persistence_key = nil
    def user_persistence_key
      @@user_persistence_key
    end

    def user_persistence_key= value
      @@user_persistence_key = value
    end

    @@user_persistence_token = nil
    def user_persistence_token
      @@user_persistence_token
    end

    def user_persistence_token= value
      @@user_persistence_token = value
    end

  end

  def current_user
    @current_user ||= user_from_credentials
  end

  def current_user= user
    @current_user = user
  end

  def sign_in user
    store_credentials user
    self.current_user = user
  end

  def signed_in?
    !!current_user
  end

  def sign_out
    clear_credentials
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
    raise YouShallNotPass.new(<<-EOT)
      This message would be rescued in your controller.

      rescue_from 'Gandalf::AuthorizationRequired' do |exception|
        # if signed_in?
        #   redirect_to root_path
        # else
        #   redirect_to sign_in_path
        # end
      end
    EOT
  end

  def authorize
    deny_access unless signed_in?
  end

  def store_credentials user
    credentials = [user.id]
    
    if user.respond_to?(user_persistence_token)
      credentials << user.send(user_persistence_token)
    end

    cookies.signed[user_persistence_key] = credentials.compact
  end

  def stored_credentials
    cookies.signed[user_persistence_key]
  end

  def clear_credentials
    cookies.delete user_persistence_key
  end

  # CSRF protection in Rails >= 3.0.4
  # http://weblog.rubyonrails.org/2011/2/8/csrf-protection-bypass-in-ruby-on-rails
  def handle_unverified_request
    super
    sign_out
  end

protected

  def retrieve_user_for_request 
    raise NotImplementedError.new(<<-EOT)
      Gandalf requires you to have defined this method. i.e.

      def retrieve_user_for_request id, token = nil
        # User.find_by_id_and_persistence_token id, token
      end
    EOT
  end

  def user_persistence_key
    self.class.user_persistence_key || :user_id
  end

  def user_persistence_token
    self.class.user_persistence_token || :persistence_token
  end

private

  def user_from_credentials
    retrieve_method = method(:retrieve_user_for_request)

    return retrieve_method.call if retrieve_method.arity == 0

    credentials = stored_credentials || []

    if retrieve_method.arity == -1
      # do nothing
    elsif credentials.size > retrieve_method.arity
      credentials = credentials.slice 0, retrieve_method.arity
    elsif credentials.size < retrieve_method.arity
      credentials += Array.new(retrieve_method.arity - credentials.size)
    end

    retrieve_method.call *credentials
  end
end
