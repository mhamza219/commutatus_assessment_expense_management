class Settlement < ApplicationRecord
  belongs_to :payer, class_name: 'User'
  belongs_to :payee, class_name: 'User'

  validates :amount, numericality: { greater_than: 0 }
  validate :payer_cannot_be_payee

  private

  def payer_cannot_be_payee
    errors.add(:payee_id, "cannot be the same as the payer") if payer_id == payee_id
  end
end
