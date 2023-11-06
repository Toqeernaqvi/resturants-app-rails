class CreateSpDriversList < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE FUNCTION sp_drivers_list(p_delivery_at TEXT, p_delivery_day TEXT, p_pickup_time TEXT, p_pickup_day TEXT, p_delivery_type TEXT, p_vendor BOOLEAN DEFAULT FALSE, p_address_ids TEXT DEFAULT NULL)
    RETURNS TABLE (
      id BIGINT,
      first_name TEXT,
      last_name TEXT
    )
    AS $$
    DECLARE
      ROW RECORD;
      SQL TEXT;
    BEGIN
      SQL = 'SELECT DISTINCT drivers.id, first_name, last_name FROM drivers
          INNER JOIN driver_shifts ON driver_shifts.driver_id = drivers.id AND (driver_shifts.label = '''|| p_delivery_day ||''' OR driver_shifts.label = '''|| p_pickup_day ||''' )';
      IF p_delivery_type = 'delivery' THEN
        SQL = SQL || 'LEFT JOIN addresses ON drivers.restaurant_address_id = addresses.id AND addresses.addressable_type = ''Restaurant'' 
            LEFT JOIN restaurants ON addresses.addressable_id = restaurants.id ';
      END IF;
      SQL = SQL || 'WHERE drivers.status = 0 AND drivers.worker_id IS NOT NULL';
      IF p_delivery_type = 'delivery' THEN
        SQL = SQL || ' AND (TO_CHAR('''|| p_delivery_at ||''' :: time, ''HH24:MI'') BETWEEN
        TO_CHAR(timezone(CASE WHEN drivers.restaurant_address_id IS NULL THEN ''US/Pacific'' ELSE restaurants.time_zone END, driver_shifts.start_time), ''HH24:MI'') AND
        TO_CHAR(timezone(CASE WHEN drivers.restaurant_address_id IS NULL THEN ''US/Pacific'' ELSE restaurants.time_zone END, driver_shifts.end_time), ''HH24:MI''))
        AND (TO_CHAR('''|| p_pickup_time ||''' :: time, ''HH:MI'') BETWEEN
        TO_CHAR(timezone(CASE WHEN drivers.restaurant_address_id IS NULL THEN ''US/Pacific'' ELSE restaurants.time_zone END, driver_shifts.start_time), ''HH24:MI'') AND
        TO_CHAR(timezone(CASE WHEN drivers.restaurant_address_id IS NULL THEN ''US/Pacific'' ELSE restaurants.time_zone END, driver_shifts.end_time), ''HH24:MI''))';
      ELSE
        SQL = SQL || ' AND drivers.restaurant_address_id IS NULL AND (TO_CHAR('''|| p_delivery_at ||''' :: time, ''HH24:MI'') BETWEEN
          TO_CHAR(timezone(''US/Pacific'', driver_shifts.start_time), ''HH24:MI'') AND
          TO_CHAR(timezone(''US/Pacific'', driver_shifts.end_time), ''HH24:MI''))
          AND (TO_CHAR('''|| p_pickup_time ||''' :: time, ''HH:MI'') BETWEEN
          TO_CHAR(timezone(''US/Pacific'', driver_shifts.start_time), ''HH24:MI'') AND
          TO_CHAR(timezone(''US/Pacific'', driver_shifts.end_time), ''HH24:MI''))';
      END IF;

      IF p_delivery_type = 'delivery' THEN
        IF p_vendor THEN
          SQL = SQL || ' AND (1=1';
        ELSE
          SQL = SQL || ' AND (drivers.restaurant_address_id IS NULL';
        END IF;
        IF p_address_ids IS NOT NULL THEN
          IF p_vendor THEN
            SQL = SQL || ' AND addresses.id IN('|| p_address_ids ||')';
          ELSE
            SQL = SQL || ' OR addresses.id IN('|| p_address_ids ||')';
          END IF;
        END IF;
        SQL = SQL || ')';
      END IF;

      FOR ROW IN EXECUTE SQL LOOP
        id := row.id::BIGINT;
        first_name := row.first_name::TEXT;
        last_name := row.last_name::TEXT;
        RETURN NEXT;
      END LOOP;
    END;
    $$ LANGUAGE plpgsql;"
  end

  def self.down
    execute "DROP FUNCTION IF EXISTS sp_drivers_list(p_delivery_at TEXT, p_delivery_day TEXT, p_pickup_time TEXT, p_pickup_day TEXT, p_delivery_type TEXT, p_vendor BOOLEAN, p_address_ids TEXT)";
  end
end
