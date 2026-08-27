require 'rails_helper'

RSpec.describe "Passwords", type: :request do
  let!(:user) { User.create!(name: "Jane Doe", email: "jane_#{SecureRandom.hex(4)}@test.com", password: "password123") }

  describe "GET /users/password/new" do
    it "renders the forgot password page successfully" do
      get new_user_password_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Forgot Password?")
      expect(response.body).to include("Send Reset Instructions")
    end
  end

  describe "POST /users/password" do
    it "sends password reset instructions when email exists" do
      expect {
        post user_password_path, params: {
          user: { email: user.email }
        }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!
      expect(response.body).to include("You will receive an email with instructions")
    end
  end

  describe "PUT /users/password" do
    it "resets the password with a valid reset token" do
      raw_token = user.send_reset_password_instructions

      put user_password_path, params: {
        user: {
          reset_password_token: raw_token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.valid_password?("newpassword123")).to be true
    end
  end
end
