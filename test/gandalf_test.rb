require 'test_helper'

class GandalfTest < ActionController::TestCase
  class SignedInRedirect < Exception; end
  class SignedOutRedirect < Exception; end

  class GandalfController < ActionController::Base
    include Gandalf

    attr_accessor :user

    gandalf_retrieve_user :user
    gandalf_persist_user :user=
  end

  tests GandalfController

  # def setup
  #   @request.env[ActionDispatch::Cookies::TOKEN_KEY] = '5809d4cdffaa2dd486a17f82457bc1c1'
  # end

  test ".gandalf_retrieve_user should return the current value when no arguments are passed" do
    assert_equal :user, @controller.class.gandalf_retrieve_user
  end

  test ".gandalf_retrieve_user should raise an error when a block is given with an arity above 1" do
    assert_raises ArgumentError do
      @controller.class.gandalf_retrieve_user{|one, two|}
    end
  end

  test ".gandalf_retrieve_user should raise an error when a block is given with an arity is zero" do
    assert_raises ArgumentError do
      @controller.class.gandalf_retrieve_user{||}
    end
  end

  test ".gandalf_persist_user should return the current value when no arguments are passed" do
    assert_equal :user=, @controller.class.gandalf_persist_user
  end

  test ".gandalf_persist_user should raise an error when a block is given with an arity above 2" do
    assert_raises ArgumentError do
      @controller.class.gandalf_persist_user{|one, two, three|}
    end
  end

  test ".gandalf_persist_user should raise an error when a block is given with an arity is zero" do
    assert_raises ArgumentError do
      @controller.class.gandalf_persist_user{||}
    end
  end

  test "#current_user should return the user" do
    user = Object.new
    @controller.user = user
    assert_equal user, @controller.current_user
  end

  test "#sign_in should set the current user" do
    user = Object.new
    @controller.sign_in user

    assert_equal user, @controller.user
  end

  test "#signed_in? should return true when current_user is set" do
    user = Object.new
    @controller.user = user

    assert @controller.signed_in?, "Expected to be signed in"
  end

  test "#signed_in? should return false when current_user is nil" do
    assert_nil @controller.current_user
    refute @controller.signed_in?, "Expected to not be signed in"
  end

  test "#sign_out should set current user to nil" do
    user = Object.new
    @controller.user = user
    @controller.sign_out

    assert_nil @controller.user
  end

  test "#signed_out? should return true when current user is nil" do
    assert_nil @controller.current_user
    assert @controller.signed_out?, "Expected to be signed out"
  end

  test "#signed_out? should return false when current user is set" do
    @controller.current_user = Object.new
    refute @controller.signed_out?, "Expected to not be signed out"
  end

  test "#store_location should store the current path to session when request is GET" do
    @request.path = '/test'
    @controller.store_location

    assert_equal '/test', session[:return_to]
  end

  test "#store_location should not store the current path when request is not GET" do
    @request.path = '/test'
    @request.request_method = 'POST'
    @controller.store_location

    assert_nil session[:return_to]
  end

  test "#clear_return_to should delete the stored path" do
    session[:return_to] = '/test'
    @controller.clear_return_to

    assert_nil session[:return_to]
  end

  test "#return_to should return the path stored in the session" do
    session[:return_to] = '/test'
    assert_equal @controller.return_to, '/test'
  end

  test "#return_to should return the path stored in the params" do
    @controller.params[:return_to] = '/test'
    assert_equal @controller.return_to, '/test'
  end

  test "#deny_access should raise AuthorizationRequired exception" do
    user = Object.new
    @controller.current_user = user

    assert_raises Gandalf::AuthorizationRequired do
      @controller.deny_access
    end
  end

  test "#deny_access should raise YouShallNotPass exception" do
    user = Object.new
    @controller.current_user = user

    assert_raises Gandalf::YouShallNotPass do
      @controller.deny_access
    end
  end

  test "#authorize should do nothing when signed in" do
    @controller.current_user = Object.new
    @controller.authorize
  end

  test "#authorize should raise exception when signed out" do
    assert_nil @controller.current_user
    assert_raises Gandalf::AuthorizationRequired do
      @controller.authorize
    end
  end

end
