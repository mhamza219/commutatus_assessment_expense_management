require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(name: "Test User", email: "user_#{SecureRandom.hex(4)}@test.com", password: "password123")
    @friend = User.create!(name: "Test Friend", email: "friend_#{SecureRandom.hex(4)}@test.com", password: "password123")
    sign_in @user
  end

  test "creates itemized expense successfully" do
    assert_difference("Expense.count", 1) do
      post expenses_path, params: {
        expense: {
          description: "Team Outing",
          tax: "5.00",
          paid_by_id: @user.id,
          items: {
            "0" => { name: "Pizza", amount: "30.00", participant_ids: [@user.id, @friend.id] },
            "1" => { name: "Drinks", amount: "10.00", participant_ids: [@friend.id] }
          }
        }
      }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match(/Team Outing/, response.body)

    expense = Expense.last
    assert_equal 45.0, expense.amount # 30 + 10 + 5
    assert_equal 2, expense.expense_items.count
    assert_equal 2, expense.expense_splits.count
  end

  test "deletes an expense successfully" do
    expense = Expense.new(paid_by: @user, description: "To Delete", tax: 0.0)
    expense.expense_items.build(name: "Coffee", amount: 8.0, participants: [@user, @friend])
    expense.save!

    assert_difference("Expense.count", -1) do
      delete expense_path(expense)
    end

    assert_redirected_to root_path
  end
end
