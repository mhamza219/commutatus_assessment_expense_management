class Expense < ApplicationRecord
  belongs_to :paid_by, class_name: 'User'
  has_many :expense_items, dependent: :destroy, inverse_of: :expense
  has_many :expense_splits, dependent: :destroy, inverse_of: :expense
  has_many :participants, through: :expense_splits, source: :user

  accepts_nested_attributes_for :expense_items, allow_destroy: true

  validates :description, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :tax, numericality: { greater_than_or_equal_to: 0 }

  before_validation :compute_total_amount_from_items, if: -> { expense_items.present? }
  after_save :recalculate_and_save_splits!

  attr_accessor :custom_participant_ids

  # Compute total bill amount if items are present
  def compute_total_amount_from_items
    items_total = expense_items.reject(&:marked_for_destruction?).sum { |item| item.amount.to_f }
    self.amount = (items_total + tax.to_f).round(2)
  end

  # Calculates and syncs expense_splits based on item assignments + tax distribution
  def recalculate_and_save_splits!
    splits_hash = Hash.new(BigDecimal('0.0'))
    active_items = expense_items.reject(&:marked_for_destruction?)

    if active_items.any?
      all_participants = Set.new

      active_items.each do |item|
        item_users = item.participants.to_a
        # If no participants explicitly assigned to item, default to paid_by or all participants
        item_users = [paid_by] if item_users.empty?
        all_participants.merge(item_users)

        item_amount = BigDecimal(item.amount.to_s)
        count = item_users.size
        next if count.zero?

        base_share = (item_amount / count).round(2)
        total_assigned = base_share * count
        diff = item_amount - total_assigned

        item_users.each_with_index do |user, idx|
          extra = (idx < (diff * 100).to_i) ? BigDecimal('0.01') : BigDecimal('0.0')
          splits_hash[user.id] += (base_share + extra)
        end
      end

      # Split tax equally among all distinct bill participants
      tax_amount = BigDecimal(tax.to_s)
      if tax_amount > 0 && all_participants.any?
        tax_count = all_participants.size
        base_tax = (tax_amount / tax_count).round(2)
        tax_assigned = base_tax * tax_count
        tax_diff = tax_amount - tax_assigned

        all_participants.each_with_index do |user, idx|
          extra = (idx < (tax_diff * 100).to_i) ? BigDecimal('0.01') : BigDecimal('0.0')
          splits_hash[user.id] += (base_tax + extra)
        end
      end
    elsif custom_participant_ids.present? || participants.any?
      ids = custom_participant_ids.presence || participants.pluck(:id)
      user_ids = Array(ids).reject(&:blank?).map(&:to_i).uniq
      user_ids << paid_by_id unless user_ids.include?(paid_by_id)

      total_bill = BigDecimal(amount.to_s)
      count = user_ids.size
      if count > 0
        base_share = (total_bill / count).round(2)
        total_assigned = base_share * count
        diff = total_bill - total_assigned

        user_ids.each_with_index do |uid, idx|
          extra = (idx < (diff * 100).to_i) ? BigDecimal('0.01') : BigDecimal('0.0')
          splits_hash[uid] = base_share + extra
        end
      end
    else
      # Default: Entire bill assigned to payer
      splits_hash[paid_by_id] = BigDecimal(amount.to_s)
    end

    # Sync splits with database
    ExpenseSplit.where(expense_id: id).where.not(user_id: splits_hash.keys).delete_all
    splits_hash.each do |user_id, share|
      split = ExpenseSplit.find_or_initialize_by(expense_id: id, user_id: user_id)
      split.amount_owed = share
      split.save!
    end
  end

  def amount_paid_by(user)
    paid_by_id == user.id ? amount : BigDecimal('0.0')
  end

  def amount_owed_by(user)
    expense_splits.find { |s| s.user_id == user.id }&.amount_owed || BigDecimal('0.0')
  end

  def net_amount_for(user)
    amount_paid_by(user) - amount_owed_by(user)
  end
end
