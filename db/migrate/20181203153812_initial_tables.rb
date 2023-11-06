class InitialTables < ActiveRecord::Migration[5.1]
  def change
    create_table :addresses do |t|
      t.references :addressable, polymorphic: true, index: true
      t.string  :formatted_address
      t.string  :street
      t.string  :city
      t.string  :state
      t.string  :zip
      t.time :starting_hours_of_operations
      t.time :ending_hours_of_operations

      t.datetime  :deleted_at, index: true
      t.timestamps
    end

    create_table :companies do |t|
      t.string     :name
      t.datetime   :deleted_at, index: true

      t.timestamps null: false
    end

    create_table :users do |t|
      t.references :company, index: true, foreign_key: true
      t.references :office_admin, index: true, foreign_key: {to_table: :users}

      # Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      # Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.string   :reset_password_redirect_url
      t.boolean  :allow_password_change, default: false

      # Rememberable
      t.datetime :remember_created_at

      # Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      # Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      # Lockable
      t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      t.string   :provider
      t.string   :uid, default: "", null: false
      t.text     :tokens
      t.string   :first_name
      t.string   :last_name
      t.string   :phone_number
      t.integer  :user_type, default: 0, null: false
      t.integer  :profile_completed, default: 0, null: false
      t.integer  :first_time, default: 0, null: false

      t.datetime  :deleted_at, index: true

      t.timestamps null: false

      t.index [:confirmation_token], name: "index_users_on_confirmation_token", unique: true
      t.index [:email], name: "index_users_on_email"
      t.index [:reset_password_token], name: "index_users_on_reset_password_token", unique: true
      t.index [:unlock_token], name: "index_users_on_unlock_token", unique: true
      t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
    end
  end
end
