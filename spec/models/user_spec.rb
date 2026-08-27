require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:alice) { User.create!(name: "Alice", email: "alice_#{SecureRandom.hex(4)}@test.com", password: "password123") }
  let!(:bob) { User.create!(name: "Bob", email: "bob_#{SecureRandom.hex(4)}@test.com", password: "password123") }
  let!(:charlie) { User.create!(name: "Charlie", email: "charlie_#{SecureRandom.hex(4)}@test.com", password: "password123") }

  describe '#balance_with' do
    it 'calculates net balance correctly when user pays for friend' do
      exp = Expense.new(paid_by: alice, description: "Lunch", amount: 40.0)
      exp.expense_items.build(name: "Burgers", amount: 40.0, participants: [alice, bob])
      exp.save!

      expect(alice.balance_with(bob)).to eq(20.0)
      expect(bob.balance_with(alice)).to eq(-20.0)
    end

    it 'handles settlement payments' do
      exp = Expense.new(paid_by: alice, description: "Lunch", amount: 40.0)
      exp.expense_items.build(name: "Burgers", amount: 40.0, participants: [alice, bob])
      exp.save!

      Settlement.create!(payer: bob, payee: alice, amount: 15.0)

      expect(alice.balance_with(bob)).to eq(5.0)
      expect(bob.balance_with(alice)).to eq(-5.0)

      Settlement.create!(payer: bob, payee: alice, amount: 5.0)

      expect(alice.balance_with(bob)).to eq(0.0)
      expect(bob.balance_with(alice)).to eq(0.0)
    end
  end

  describe '#dashboard_summary' do
    it 'accurately aggregates total due, you owe, and total balance' do
      # Alice pays for Bob ($20 owed to Alice)
      exp1 = Expense.new(paid_by: alice, description: "Lunch", amount: 40.0)
      exp1.expense_items.build(name: "Burgers", amount: 40.0, participants: [alice, bob])
      exp1.save!

      # Charlie pays for Alice ($30 Alice owes Charlie)
      exp2 = Expense.new(paid_by: charlie, description: "Dinner", amount: 60.0)
      exp2.expense_items.build(name: "Steaks", amount: 60.0, participants: [alice, charlie])
      exp2.save!

      summary = alice.dashboard_summary

      expect(summary[:total_due_to_you]).to eq(20.0)
      expect(summary[:total_you_owe]).to eq(30.0)
      expect(summary[:total_balance]).to eq(-10.0)
      expect(summary[:friends_who_owe_you].size).to eq(1)
      expect(summary[:friends_you_owe].size).to eq(1)
    end
  end

  describe '#friends' do
    it 'returns all other users' do
      expect(alice.friends).to include(bob, charlie)
      expect(alice.friends).not_to include(alice)
    end
  end
end
