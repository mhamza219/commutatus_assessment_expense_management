class ExpensesController < ApplicationController
  def create
    @expense = Expense.new(expense_params)
    @expense.paid_by ||= current_user

    # Process items and participant_ids if submitted via nested params
    if params[:expense][:items].present?
      params[:expense][:items].each do |_idx, item_params|
        next if item_params[:name].blank? || item_params[:amount].blank?

        item = @expense.expense_items.build(
          name: item_params[:name],
          amount: item_params[:amount],
          split_type: item_params[:split_type].presence || 'equal'
        )

        p_ids = Array(item_params[:participant_ids]).reject(&:blank?)
        if p_ids.empty?
          # If no individual selected, default to all bill participants or payer
          item.participants = User.where(id: params[:expense][:participant_ids])
        else
          item.participants = User.where(id: p_ids)
        end
      end
    elsif params[:expense][:participant_ids].present?
      @expense.custom_participant_ids = params[:expense][:participant_ids]
    end

    if @expense.save
      redirect_back fallback_location: root_path, notice: "Expense '#{@expense.description}' added successfully!"
    else
      redirect_back fallback_location: root_path, alert: "Failed to add expense: #{@expense.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @expense = Expense.find(params[:id])
    description = @expense.description
    @expense.destroy
    redirect_back fallback_location: root_path, notice: "Expense '#{description}' was deleted."
  end

  private

  def expense_params
    params.require(:expense).permit(:description, :amount, :tax, :paid_by_id, :date)
  end
end
