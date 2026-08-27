class ExpenseItem < ApplicationRecord
  belongs_to :expense, inverse_of: :expense_items
  has_many :expense_item_participants, dependent: :destroy, inverse_of: :expense_item
  has_many :participants, through: :expense_item_participants, source: :user

  validates :name, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  # Helper to set participants by user IDs
  def participant_ids=(ids)
    clean_ids = Array(ids).reject(&:blank?).map(&:to_i).uniq
    self.participants = User.where(id: clean_ids)
  end
end
