class ExpenseSplit < ApplicationRecord
  belongs_to :expense, inverse_of: :expense_splits
  belongs_to :user

  validates :amount_owed, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :expense_id }
end
