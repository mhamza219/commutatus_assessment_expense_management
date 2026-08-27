require 'rails_helper'

RSpec.describe "StaticPages", type: :request do
  let!(:user) { User.create!(name: "Test User", email: "user_#{SecureRandom.hex(4)}@test.com", password: "password123") }
  let!(:friend) { User.create!(name: "Test Friend", email: "friend_#{SecureRandom.hex(4)}@test.com", password: "password123") }

  before do
    sign_in user
  end

  describe "GET /" do
    it "renders the dashboard successfully" do
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Dashboard")
      expect(response.body).to include("total balance")
    end
  end

  describe "GET /people/:id" do
    it "renders the friend page successfully" do
      get person_path(friend)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(friend.name)
    end
  end
end
