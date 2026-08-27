require "test_helper"

class SettlementsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(name: "Test User", email: "user_#{SecureRandom.hex(4)}@test.com", password: "password123")
    @friend = User.create!(name: "Test Friend", email: "friend_#{SecureRandom.hex(4)}@test.com", password: "password123")
    sign_in @user
  end

  test "records a settlement payment successfully" do
    assert_difference("Settlement.count", 1) do
      post settlements_path, params: {
        settlement: {
          payee_id: @friend.id,
          amount: "25.00",
          notes: "Cash payment"
        }
      }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match(/Successfully recorded payment/, response.body)

    settlement = Settlement.last
    assert_equal @user, settlement.payer
    assert_equal @friend, settlement.payee
    assert_equal 25.0, settlement.amount
  end
end
