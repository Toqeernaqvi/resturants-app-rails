class AddEnqueuedForInvoiceToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :enqueued_for_invoice, :boolean, default: false
  end
end
