class CreateSequences < ActiveRecord::Migration[5.1]
  def change
    create_table :cuisineslists do |t|
      t.string :name
      t.integer :status, default: 0
      t.timestamps
    end
    create_table :addresses_cuisineslists do |t|
      t.belongs_to :address
      t.belongs_to :cuisineslist
      t.integer :position, default: 0
      t.timestamps
    end
    add_index :addresses_cuisineslists, [:address_id, :cuisineslist_id], unique: true

    create_table :sequences do |t|
      t.string :name
      t.integer :restaurants_served, default: 1
      t.integer :status, default: 0
      t.timestamps
    end    
    create_table :labels_seqs do |t|
      t.belongs_to :sequence
      t.string :title
      t.integer :position, default: 0
      t.timestamps
    end
    create_table :cuisines_sequences do |t|
      t.belongs_to :cuisineslist
      t.belongs_to :labels_seq
      t.integer :position, default: 0
      t.timestamps
    end
    # add_index :cuisines_sequences, [:cuisineslist_id, :labels_seq_id], unique: true
  end
end
