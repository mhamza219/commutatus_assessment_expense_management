require 'rails_helper'

RSpec.describe Expense, type: :model do
  let!(:john) { User.create!(name: "John", email: "john_#{SecureRandom.hex(4)}@test.com", password: "password123") }
  let!(:alice) { User.create!(name: "Alice", email: "alice_#{SecureRandom.hex(4)}@test.com", password: "password123") }
  let!(:bob) { User.create!(name: "Bob", email: "bob_#{SecureRandom.hex(4)}@test.com", password: "password123") }

  describe 'itemized bill splitting' do
    it 'correctly assigns individual items and splits shared items and tax' do
      expense = Expense.new(paid_by: john, description: "Group Dinner", tax: 6.0)

      # Item 1: Juice ($10) -> Alice only
      expense.expense_items.build(name: "Juice", amount: 10.0, participants: [alice])

      # Item 2: Main Dish ($40) -> John and Alice ($20 each)
      expense.expense_items.build(name: "Main Dish", amount: 40.0, participants: [john, alice])

      # Item 3: Dessert ($15) -> John, Alice, Bob ($5 each)
      expense.expense_items.build(name: "Dessert", amount: 15.0, participants: [john, alice, bob])

      # Tax ($6) split equally among 3 distinct participants -> $2 each
      expense.save!

      expect(expense.amount).to eq(71.0)

      # Alice share: $10 + $20 + $5 + $2 = $37
      alice_split = expense.expense_splits.find_by(user: alice)
      expect(alice_split.amount_owed).to eq(37.0)

      # John share: $20 + $5 + $2 = $27
      john_split = expense.expense_splits.find_by(user: john)
      expect(john_split.amount_owed).to eq(27.0)

      # Bob share: $5 + $2 = $7
      bob_split = expense.expense_splits.find_by(user: bob)
      expect(bob_split.amount_owed).to eq(7.0)

      # Total splits match total bill
      expect(expense.expense_splits.sum(:amount_owed)).to eq(71.0)
    end

    it 'handles fractional cents remainder distribution accurately' do
      expense = Expense.new(paid_by: john, description: "Fractional Split", tax: 1.0)
      expense.expense_items.build(name: "Shared Item", amount: 10.0, participants: [john, alice, bob])
      expense.save!

      expect(expense.amount).to eq(11.0)
      expect(expense.expense_splits.sum(:amount_owed)).to eq(11.0)
      expect(expense.expense_splits.pluck(:amount_owed).map(&:to_f).sort).to eq([3.66, 3.66, 3.68])
    end

    it 'handles non-participating payer correctly' do
      expense = Expense.new(paid_by: john, description: "Treat Friends", tax: 0.0)
      expense.expense_items.build(name: "Gift for Alice", amount: 30.0, participants: [alice])
      expense.expense_items.build(name: "Gift for Bob", amount: 20.0, participants: [bob])
      expense.save!

      expect(expense.amount).to eq(50.0)
      expect(expense.expense_splits.find_by(user: john)).to be_nil
      expect(john.balance_with(alice)).to eq(30.0)
      expect(john.balance_with(bob)).to eq(20.0)
    end
  end

  describe 'destruction' do
    it 'cascades deletion to splits and items' do
      expense = Expense.new(paid_by: john, description: "Groceries", tax: 0.0)
      expense.expense_items.build(name: "Milk", amount: 5.0, participants: [john, alice])
      expense.save!

      split_ids = expense.expense_splits.pluck(:id)
      item_ids = expense.expense_items.pluck(:id)

      expense.destroy!

      expect(ExpenseSplit.where(id: split_ids)).to be_empty
      expect(ExpenseItem.where(id: item_ids)).to be_empty
    end
  end
end
