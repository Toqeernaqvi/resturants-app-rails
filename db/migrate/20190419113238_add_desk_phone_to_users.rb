class AddDeskPhoneToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :desk_phone, :string, after: :phone_number

    CompanyAdmin.all.each do |u|
      if u.phone_number.present?
        u.update_column(:desk_phone, u.phone_number)
      end
    end
  end
end
