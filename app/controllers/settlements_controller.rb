class SettlementsController < ApplicationController
  def create
    @settlement = current_user.settlements_paid.build(settlement_params)
    @settlement.date ||= Date.current

    if @settlement.save
      redirect_back fallback_location: root_path, notice: "Successfully recorded payment of $#{sprintf('%.2f', @settlement.amount)} to #{@settlement.payee.name}!"
    else
      redirect_back fallback_location: root_path, alert: "Could not record payment: #{@settlement.errors.full_messages.join(', ')}"
    end
  end

  private

  def settlement_params
    params.require(:settlement).permit(:payee_id, :amount, :notes, :date)
  end
end
