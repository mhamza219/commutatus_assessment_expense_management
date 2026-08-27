require 'rails_helper'

RSpec.describe Settlement, type: :model do
  let!(:alice) { User.create!(name: "Alice", email: "alice_#{SecureRandom.hex(4)}@test.com", password: "password123") }
  let!(:bob) { User.create!(name: "Bob", email: "bob_#{SecureRandom.hex(4)}@test.com", password: "password123") }

  it 'is valid with valid payer, payee, and positive amount' do
    settlement = Settlement.new(payer: alice, payee: bob, amount: 25.50, notes: "Dinner payoff")
    expect(settlement).to be_valid
  end

  it 'is invalid if payer and payee are the same user' do
    settlement = Settlement.new(payer: alice, payee: alice, amount: 25.50)
    expect(settlement).not_to be_valid
    expect(settlement.errors[:payee_id]).to include("cannot be the same as the payer")
  end

  it 'is invalid if amount is zero or negative' do
    settlement = Settlement.new(payer: alice, payee: bob, amount: 0.0)
    expect(settlement).not_to be_valid
    expect(settlement.errors[:amount]).to include("must be greater than 0")
  end
end
