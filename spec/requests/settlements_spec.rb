require 'rails_helper'

RSpec.describe "Settlements", type: :request do
  let!(:user) { User.create!(name: "Test User", email: "user_#{SecureRandom.hex(4)}@test.com", password: "password123") }
  let!(:friend) { User.create!(name: "Test Friend", email: "friend_#{SecureRandom.hex(4)}@test.com", password: "password123") }

  before do
    sign_in user
  end

  describe "POST /settlements" do
    it "records a settlement payment successfully" do
      expect {
        post settlements_path, params: {
          settlement: {
            payee_id: friend.id,
            amount: "25.00",
            notes: "Cash payment"
          }
        }
      }.to change(Settlement, :count).by(1)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Successfully recorded payment")

      settlement = Settlement.last
      expect(settlement.payer).to eq(user)
      expect(settlement.payee).to eq(friend)
      expect(settlement.amount).to eq(25.0)
    end
  end
end
