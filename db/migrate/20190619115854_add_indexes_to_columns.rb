class AddIndexesToColumns < ActiveRecord::Migration[5.1]
  def change
    ["addresses", "companies", "cuisines", "dietaries", "email_logs", "fieldoptions", "fields", "fooditems", "gfooditems", "gmenus", "goptions", "goptionsets", "gsections", "ingredients", "invoices", "menus", "options", "optionsets", "orders", "payment_logs", "restaurants", "runningmenus", "sections", "users"].each do |table_name|
      model = table_name.split('_').map(&:capitalize).map(&:singularize).join("").constantize
      table_name = table_name.to_sym
      unless model.connection.index_exists?(table_name, :status)
        add_index table_name, :status  
      end  
    end
    
    add_index :users, [:user_type, :uid]
    add_index :menus, :menu_type
    add_index :fields, :name
    add_index :sections, :position
    add_index :gsections, :position
    add_index :fooditems, :position
    add_index :gfooditems, :position
    add_index :optionsets, :position
    add_index :goptionsets, :position
    add_index :options, :position
    add_index :goptions, :position
  end
end
