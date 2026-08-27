class CreateExpenseTrackingTables < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :paid_by, null: false, foreign_key: { to_table: :users }
      t.string :description, null: false
      t.decimal :amount, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :tax, precision: 10, scale: 2, default: 0.0, null: false
      t.date :date, default: -> { 'CURRENT_DATE' }

      t.timestamps
    end

    create_table :expense_items do |t|
      t.references :expense, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.decimal :amount, precision: 10, scale: 2, default: 0.0, null: false
      t.string :split_type, default: "equal"

      t.timestamps
    end

    create_table :expense_item_participants do |t|
      t.references :expense_item, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :expense_item_participants, [:expense_item_id, :user_id], unique: true, name: 'idx_item_participants'

    create_table :expense_splits do |t|
      t.references :expense, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :amount_owed, precision: 10, scale: 2, default: 0.0, null: false

      t.timestamps
    end
    add_index :expense_splits, [:expense_id, :user_id], unique: true

    create_table :settlements do |t|
      t.references :payer, null: false, foreign_key: { to_table: :users }
      t.references :payee, null: false, foreign_key: { to_table: :users }
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.text :notes
      t.date :date, default: -> { 'CURRENT_DATE' }

      t.timestamps
    end
  end
end
