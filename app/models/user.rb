class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :paid_expenses, class_name: 'Expense', foreign_key: :paid_by_id, dependent: :destroy
  has_many :expense_splits, dependent: :destroy
  has_many :participating_expenses, through: :expense_splits, source: :expense

  has_many :settlements_paid, class_name: 'Settlement', foreign_key: :payer_id, dependent: :destroy
  has_many :settlements_received, class_name: 'Settlement', foreign_key: :payee_id, dependent: :destroy

  validates :name, presence: true

  # All other users as friends
  def friends
    User.where.not(id: id).order(:name)
  end

  # Net balance between self and another user:
  # Positive (+) => other_user owes self
  # Negative (-) => self owes other_user
  # Zero (0) => all settled
  def balance_with(other_user)
    return BigDecimal('0.0') if other_user.nil? || other_user.id == id

    # What other_user owes self from expenses where self paid
    lent_from_expenses = ExpenseSplit.joins(:expense)
                                    .where(expenses: { paid_by_id: id }, user_id: other_user.id)
                                    .sum(:amount_owed)

    # What self owes other_user from expenses where other_user paid
    borrowed_from_expenses = ExpenseSplit.joins(:expense)
                                        .where(expenses: { paid_by_id: other_user.id }, user_id: id)
                                        .sum(:amount_owed)

    # Payments made by self to other_user
    paid_settlements = settlements_paid.where(payee_id: other_user.id).sum(:amount)

    # Payments received by self from other_user
    received_settlements = settlements_received.where(payer_id: other_user.id).sum(:amount)

    (lent_from_expenses + paid_settlements) - (borrowed_from_expenses + received_settlements)
  end

  # Generates dashboard summary containing you owe, you are owed, and total balance
  def dashboard_summary
    friends_you_owe = []
    friends_who_owe_you = []

    friends.each do |friend|
      bal = balance_with(friend)
      if bal > 0
        friends_who_owe_you << { user: friend, amount: bal.round(2) }
      elsif bal < 0
        friends_you_owe << { user: friend, amount: (-bal).round(2) }
      end
    end

    total_due_to_you = friends_who_owe_you.sum { |item| item[:amount] }
    total_you_owe = friends_you_owe.sum { |item| item[:amount] }
    total_balance = total_due_to_you - total_you_owe

    {
      friends_you_owe: friends_you_owe,
      friends_who_owe_you: friends_who_owe_you,
      total_due_to_you: total_due_to_you.round(2),
      total_you_owe: total_you_owe.round(2),
      total_balance: total_balance.round(2)
    }
  end

  # Expenses that involve both self and the other user
  def expenses_with(other_user)
    Expense.joins(:expense_splits)
           .where(
             "(expenses.paid_by_id = :self_id AND expense_splits.user_id = :other_id) OR " \
             "(expenses.paid_by_id = :other_id AND expense_splits.user_id = :self_id)",
             self_id: id, other_id: other_user.id
           )
           .distinct
           .order(created_at: :desc)
  end
end
