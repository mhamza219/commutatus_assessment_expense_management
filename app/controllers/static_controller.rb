class StaticController < ApplicationController
  def dashboard
    @user = current_user
    @friends = @user.friends
    @dashboard_summary = @user.dashboard_summary
    @expense = Expense.new(paid_by: @user)
    @settlement = Settlement.new(payer: @user)
  end

  def person
    @user = current_user
    @friends = @user.friends
    @friend = User.find(params[:id])
    @balance_with_friend = @user.balance_with(@friend)
    @expenses = @user.expenses_with(@friend)
    @expense = Expense.new(paid_by: @user)
    @settlement = Settlement.new(payer: @user, payee: @friend)
  end
end
