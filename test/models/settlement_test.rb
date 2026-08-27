require "test_helper"

class SettlementTest < ActiveSupport::TestCase
  def setup
    @alice = User.create!(name: "Alice", email: "alice_#{SecureRandom.hex(4)}@test.com", password: "password123")
    @bob = User.create!(name: "Bob", email: "bob_#{SecureRandom.hex(4)}@test.com", password: "password123")
  end

  test "valid settlement saves successfully" do
    settlement = Settlement.new(payer: @alice, payee: @bob, amount: 25.50, notes: "Dinner payoff")
    assert settlement.valid?
    assert settlement.save
  end

  test "cannot settle with oneself" do
    settlement = Settlement.new(payer: @alice, payee: @alice, amount: 25.50)
    assert_not settlement.valid?
    assert_includes settlement.errors[:payee_id], "cannot be the same as the payer"
  end

  test "amount must be greater than zero" do
    settlement = Settlement.new(payer: @alice, payee: @bob, amount: 0.0)
    assert_not settlement.valid?
    assert_includes settlement.errors[:amount], "must be greater than 0"
  end
end
