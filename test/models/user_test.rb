require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @alice = User.create!(name: "Alice", email: "alice_#{SecureRandom.hex(4)}@test.com", password: "password123")
    @bob = User.create!(name: "Bob", email: "bob_#{SecureRandom.hex(4)}@test.com", password: "password123")
    @charlie = User.create!(name: "Charlie", email: "charlie_#{SecureRandom.hex(4)}@test.com", password: "password123")
  end

  test "balance_with calculates net balance correctly when user pays for friend" do
    exp = Expense.new(paid_by: @alice, description: "Lunch", amount: 40.0)
    exp.expense_items.build(name: "Burgers", amount: 40.0, participants: [@alice, @bob])
    exp.save!

    assert_equal 20.0, @alice.balance_with(@bob)
    assert_equal(-20.0, @bob.balance_with(@alice))
  end

  test "balance_with handles settlement payments" do
    exp = Expense.new(paid_by: @alice, description: "Lunch", amount: 40.0)
    exp.expense_items.build(name: "Burgers", amount: 40.0, participants: [@alice, @bob])
    exp.save!

    # Bob settles $15 to Alice
    Settlement.create!(payer: @bob, payee: @alice, amount: 15.0)

    assert_equal 5.0, @alice.balance_with(@bob)
    assert_equal(-5.0, @bob.balance_with(@alice))

    # Bob settles the remaining $5
    Settlement.create!(payer: @bob, payee: @alice, amount: 5.0)

    assert_equal 0.0, @alice.balance_with(@bob)
    assert_equal 0.0, @bob.balance_with(@alice)
  end

  test "dashboard_summary accurately aggregates total due, you owe, and total balance" do
    # Alice pays for Bob ($20 owed to Alice)
    exp1 = Expense.new(paid_by: @alice, description: "Lunch", amount: 40.0)
    exp1.expense_items.build(name: "Burgers", amount: 40.0, participants: [@alice, @bob])
    exp1.save!

    # Charlie pays for Alice ($30 Alice owes Charlie)
    exp2 = Expense.new(paid_by: @charlie, description: "Dinner", amount: 60.0)
    exp2.expense_items.build(name: "Steaks", amount: 60.0, participants: [@alice, @charlie])
    exp2.save!

    summary = @alice.dashboard_summary

    assert_equal 20.0, summary[:total_due_to_you]
    assert_equal 30.0, summary[:total_you_owe]
    assert_equal(-10.0, summary[:total_balance])
    assert_equal 1, summary[:friends_who_owe_you].size
    assert_equal 1, summary[:friends_you_owe].size
  end
end
