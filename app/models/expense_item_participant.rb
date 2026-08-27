class ExpenseItemParticipant < ApplicationRecord
  belongs_to :expense_item
  belongs_to :user

  validates :user_id, uniqueness: { scope: :expense_item_id }
end
