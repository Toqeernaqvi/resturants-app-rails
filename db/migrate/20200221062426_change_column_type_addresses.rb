class ChangeColumnTypeAddresses < ActiveRecord::Migration[5.1]
   def up
    execute("ALTER TABLE addresses ALTER COLUMN latitude drop default")
    execute("ALTER TABLE addresses ALTER COLUMN longitude drop default")
    execute "ALTER TABLE addresses ALTER COLUMN latitude TYPE float USING (NULLIF(latitude, '')::float)"
    execute "ALTER TABLE addresses ALTER COLUMN longitude TYPE float USING (NULLIF(longitude, '')::float)"
  end

  def down
    execute 'ALTER TABLE addresses ALTER COLUMN latitude TYPE text USING (latitude::text)'
    execute 'ALTER TABLE addresses ALTER COLUMN longitude TYPE text USING (longitude::text)'
  end
end
