class AddchoicetypetoGoptionsets < ActiveRecord::Migration[5.1]
  def change
    add_column :goptionsets, :choice_type, :integer, after: :gmenu_id
  end
end
