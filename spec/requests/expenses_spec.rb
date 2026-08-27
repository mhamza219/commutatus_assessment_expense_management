require 'rails_helper'

RSpec.describe "Expenses", type: :request do
  let!(:user) { User.create!(name: "Test User", email: "user_#{SecureRandom.hex(4)}@test.com", password: "password123") }
  let!(:friend) { User.create!(name: "Test Friend", email: "friend_#{SecureRandom.hex(4)}@test.com", password: "password123") }

  before do
    sign_in user
  end

  describe "POST /expenses" do
    it "creates an itemized expense successfully" do
      expect {
        post expenses_path, params: {
          expense: {
            description: "Team Outing",
            tax: "5.00",
            paid_by_id: user.id,
            items: {
              "0" => { name: "Pizza", amount: "30.00", participant_ids: [user.id, friend.id] },
              "1" => { name: "Drinks", amount: "10.00", participant_ids: [friend.id] }
            }
          }
        }
      }.to change(Expense, :count).by(1)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Team Outing")

      expense = Expense.last
      expect(expense.amount).to eq(45.0)
      expect(expense.expense_items.count).to eq(2)
      expect(expense.expense_splits.count).to eq(2)
    end
  end

  describe "DELETE /expenses/:id" do
    it "deletes the expense successfully" do
      expense = Expense.new(paid_by: user, description: "To Delete", tax: 0.0)
      expense.expense_items.build(name: "Coffee", amount: 8.0, participants: [user, friend])
      expense.save!

      expect {
        delete expense_path(expense)
      }.to change(Expense, :count).by(-1)

      expect(response).to redirect_to(root_path)
    end
  end
end
