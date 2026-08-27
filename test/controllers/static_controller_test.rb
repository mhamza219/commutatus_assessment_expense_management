require "test_helper"

class StaticControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(name: "Test User", email: "user_#{SecureRandom.hex(4)}@test.com", password: "password123")
    @friend = User.create!(name: "Test Friend", email: "friend_#{SecureRandom.hex(4)}@test.com", password: "password123")
    sign_in @user
  end

  test "should get dashboard" do
    get root_path
    assert_response :success
    assert_select "h1.top-bar-title", "Dashboard"
    assert_select ".balances-bar"
  end

  test "should get person page" do
    get person_path(@friend)
    assert_response :success
    assert_select "h1.top-bar-title", @friend.name
  end
end
