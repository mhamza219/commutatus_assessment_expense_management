require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  def setup
    @john = User.create!(name: "John", email: "john_#{SecureRandom.hex(4)}@test.com", password: "password123")
    @alice = User.create!(name: "Alice", email: "alice_#{SecureRandom.hex(4)}@test.com", password: "password123")
    @bob = User.create!(name: "Bob", email: "bob_#{SecureRandom.hex(4)}@test.com", password: "password123")
  end

  test "itemized expense correctly assigns individual item and splits shared item and tax" do
    expense = Expense.new(paid_by: @john, description: "Group Dinner", tax: 6.0)

    # Item 1: Juice ($10) -> Alice only
    expense.expense_items.build(name: "Juice", amount: 10.0, participants: [@alice])

    # Item 2: Main Dish ($40) -> John and Alice ($20 each)
    expense.expense_items.build(name: "Main Dish", amount: 40.0, participants: [@john, @alice])

    # Item 3: Dessert ($15) -> John, Alice, Bob ($5 each)
    expense.expense_items.build(name: "Dessert", amount: 15.0, participants: [@john, @alice, @bob])

    # Tax ($6) split equally among 3 distinct participants -> $2 each

    expense.save!

    assert_equal 71.0, expense.amount

    # Alice share: $10 (juice) + $20 (main) + $5 (dessert) + $2 (tax) = $37
    alice_split = expense.expense_splits.find_by(user: @alice)
    assert_not_nil alice_split
    assert_equal 37.0, alice_split.amount_owed

    # John share: $20 (main) + $5 (dessert) + $2 (tax) = $27
    john_split = expense.expense_splits.find_by(user: @john)
    assert_not_nil john_split
    assert_equal 27.0, john_split.amount_owed

    # Bob share: $5 (dessert) + $2 (tax) = $7
    bob_split = expense.expense_splits.find_by(user: @bob)
    assert_not_nil bob_split
    assert_equal 7.0, bob_split.amount_owed

    # Total of all splits equals total bill amount
    assert_equal expense.amount, expense.expense_splits.sum(:amount_owed)
  end

  test "handles fractional cents remainder distribution accurately" do
    expense = Expense.new(paid_by: @john, description: "Fractional Split", tax: 1.0)
    # $10 split among 3 users + $1 tax split among 3 users = $11 total
    expense.expense_items.build(name: "Shared Item", amount: 10.0, participants: [@john, @alice, @bob])
    expense.save!

    assert_equal 11.0, expense.amount
    splits_sum = expense.expense_splits.sum(:amount_owed)
    assert_equal 11.0, splits_sum

    # Each person gets ~$3.67 / $3.67 / $3.66
    splits = expense.expense_splits.pluck(:amount_owed).map(&:to_f).sort
    assert_equal [3.66, 3.66, 3.68], splits
  end

  test "payer not in any item gets 0 split and is owed full amount" do
    expense = Expense.new(paid_by: @john, description: "Treat Friends", tax: 0.0)
    expense.expense_items.build(name: "Gift for Alice", amount: 30.0, participants: [@alice])
    expense.expense_items.build(name: "Gift for Bob", amount: 20.0, participants: [@bob])
    expense.save!

    assert_equal 50.0, expense.amount
    assert_nil expense.expense_splits.find_by(user: @john)
    assert_equal 30.0, @john.balance_with(@alice)
    assert_equal 20.0, @john.balance_with(@bob)
  end

  test "deleting an expense cleans up splits and items" do
    expense = Expense.new(paid_by: @john, description: "Groceries", tax: 0.0)
    expense.expense_items.build(name: "Milk", amount: 5.0, participants: [@john, @alice])
    expense.save!

    split_ids = expense.expense_splits.pluck(:id)
    item_ids = expense.expense_items.pluck(:id)

    expense.destroy!

    assert_equal 0, ExpenseSplit.where(id: split_ids).count
    assert_equal 0, ExpenseItem.where(id: item_ids).count
  end
end
