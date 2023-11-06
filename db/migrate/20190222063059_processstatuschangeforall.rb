class Processstatuschangeforall < ActiveRecord::Migration[5.1]
  def change
    Order.update_all(process: Order.processes['yes'])
  end
end
