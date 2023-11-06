class CreateViewInvoices < ActiveRecord::Migration[5.1]
  def self.up
    execute "CREATE OR REPLACE VIEW view_invoices AS
      SELECT invoices.id AS invoice_id, invoice_number, bill_to, total_amount_due AS total_due, SUM(line_items.amount) AS delivery_fee, DATE((CASE WHEN invoices.from IS NULL THEN invoices.ship_date ELSE invoices.from END) AT TIME ZONE companies.time_zone) AS ship_range_from_date, ((CASE WHEN invoices.from IS NULL THEN invoices.ship_date ELSE invoices.from END) AT TIME ZONE companies.time_zone)::TIME AS ship_range_from_time, DATE((CASE WHEN invoices.to IS NULL THEN invoices.ship_date ELSE invoices.to END) AT TIME ZONE companies.time_zone) AS ship_range_to_date, ((CASE WHEN invoices.to IS NULL THEN invoices.ship_date ELSE invoices.to END) AT TIME ZONE companies.time_zone)::TIME AS ship_range_to_time, DATE(due_date AT TIME ZONE companies.time_zone) AS due_date, (due_date AT TIME ZONE companies.time_zone)::TIME AS due_time, DATE(invoices.created_at AT TIME ZONE companies.time_zone) AS created_date, (invoices.created_at AT TIME ZONE companies.time_zone)::TIME AS created_time, CASE WHEN invoices.status = 0 THEN 'generated' WHEN invoices.status = 1 THEN 'sent' WHEN invoices.status = 2 THEN 'paid' WHEN invoices.status = 3 THEN 'deposited' END AS status
      FROM invoices
      INNER JOIN companies ON companies.id = invoices.company_id
      LEFT JOIN line_items ON invoices.id = line_items.invoice_id AND line_items.item ILIKE '%delivery%'
      GROUP BY invoices.id, companies.id;"
  end
  def self.down
    execute "DROP VIEW IF EXISTS view_invoices;"
  end
end
