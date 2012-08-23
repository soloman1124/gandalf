require 'test_helper'

class GandalfTest < ActionController::TestCase
  class SignedInRedirect < Exception; end
  class SignedOutRedirect < Exception; end

  class GandalfController < ActionController::Base
    include Gandalf

    attr_reader :retrieve_user_for_request_arguments

    def retrieve_user_for_request *args
      @retrieve_user_for_request_arguments = args
      nil
    end

    public :user_persistence_key, :user_persistence_token
  end

  tests GandalfController

  def setup
    @request.env[ActionDispatch::Cookies::TOKEN_KEY] = '5809d4cdffaa2dd486a17f82457bc1c1'
  end

  test "#user_persistence_key when class definition is nil should return default value" do
    assert_nil @controller.class.user_persistence_key
    assert_equal :user_id, @controller.user_persistence_key
  end

  test "#user_persistence_key when class definition is set should return the value defined on the class" do
    begin
      @controller.class.user_persistence_key = :test_id
      assert_equal :test_id, @controller.user_persistence_key
    ensure
      @controller.class.user_persistence_key = nil
    end
  end

  test "#user_persistence_token when class definition is nil should return default value" do
    assert_nil @controller.class.user_persistence_token
    assert_equal :persistence_token, @controller.user_persistence_token
  end

  test "#user_persistence_token when class definition is set should return the value defined on the class" do
    begin
      @controller.class.user_persistence_token = :test_token
      assert_equal :test_token, @controller.user_persistence_token
    ensure
      @controller.class.user_persistence_token = nil
    end
  end

  test "#current_user should return the user" do
    user = MiniTest::Mock.new
    @controller.current_user = user

    assert_equal user, @controller.current_user
  end

  test "#sign_in should set the current user" do
    user = MiniTest::Mock.new
    user.expect :id, 1
    user.expect :persistence_token, nil
    @controller.sign_in user

    assert_equal user, @controller.current_user
  end

  test "#sign_in should set the cookie" do
    user = MiniTest::Mock.new
    user.expect :id, 1
    user.expect :persistence_token, nil

    assert_nil cookies[:user_id]
    @controller.sign_in user
    refute_nil cookies[:user_id]
  end

  test "#signed_in? should return true when current_user is set" do
    user = MiniTest::Mock.new
    @controller.current_user = user

    assert @controller.signed_in?, "Expected to be signed in"
  end

  test "#signed_in? should return false when current_user is nil" do
    assert_nil @controller.current_user
    refute @controller.signed_in?, "Expected to not be signed in"
  end

  test "#sign_out should set current user to nil" do
    user = MiniTest::Mock.new
    @controller.current_user = user
    @controller.sign_out

    assert_nil @controller.current_user
  end

  test "#sign_out should remove the cookie" do
    cookies[:user_id] = 1
    @controller.sign_out

    assert_nil cookies[:user_id]
  end

  test "#signed_out? should return true when current user is nil" do
    assert_nil @controller.current_user
    assert @controller.signed_out?, "Expected to be signed out"
  end

  test "#signed_out? should return false when current user is set" do
    user = MiniTest::Mock.new
    @controller.current_user = user

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
    user = MiniTest::Mock.new
    @controller.current_user = user

    assert_raises Gandalf::AuthorizationRequired do
      @controller.deny_access
    end
  end

  test "#deny_access should raise YouShallNotPass exception" do
    user = MiniTest::Mock.new
    @controller.current_user = user

    assert_raises Gandalf::YouShallNotPass do
      @controller.deny_access
    end
  end

  test "#authorize should do nothing when signed in" do
    user = MiniTest::Mock.new
    @controller.current_user = user
    @controller.authorize
  end

  test "#authorize should raise exception when signed out" do
    assert_nil @controller.current_user
    assert_raises Gandalf::AuthorizationRequired do
      @controller.authorize
    end
  end

  test "#retrieve_user_for_request should receive the id as an argument" do
    user = MiniTest::Mock.new
    user.expect :id, 1
    # sign in user to set the cookie
    @controller.sign_in user
    # clear the user but still keep the cookie
    @controller.current_user = nil
    # will force fetching the user from the cookie
    @controller.current_user
    refute_nil @controller.retrieve_user_for_request_arguments
    assert_equal user.id, @controller.retrieve_user_for_request_arguments[0]
  end

  test "#store_credentials should store the user id in a signed cookie" do
    user = Class.new do
      def id; 1; end
    end.new
    @controller.store_credentials user

    assert_equal [user.id], cookies.signed[:user_id]
  end

  test "#store_credentials should store the user persistence token in a signed cookie" do
    user = MiniTest::Mock.new
    user.expect :id, 1
    user.expect :persistence_token, 'abc123'
    @controller.store_credentials user

    assert_equal [user.id, user.persistence_token], cookies.signed[:user_id]
  end

  test "#stored_credentials should return the user id and persistence token" do
    cookies.signed[:user_id] = [1, 'abc123']
    assert_equal [1, 'abc123'], @controller.stored_credentials
  end

  test "#stored_credentials when no user credentials exist should return nil" do
    assert_nil cookies.signed[:user_id]
    assert_nil @controller.stored_credentials
  end

  test "#retrieve_user_for_request should receive the token as an argument" do
    user = MiniTest::Mock.new
    user.expect :id, 1
    user.expect :persistence_token, 'abc123'
    # sign in user to set the cookie
    @controller.sign_in user
    # clear the user but still keep the cookie
    @controller.current_user = nil
    # will force fetching the user from the cookie
    @controller.current_user
    refute_nil @controller.retrieve_user_for_request_arguments
    assert_equal user.persistence_token, @controller.retrieve_user_for_request_arguments[1]
  end
end
