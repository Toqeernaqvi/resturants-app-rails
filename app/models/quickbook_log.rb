class QuickbookLog < ApplicationRecord
	enum upload_type: [:invoice, :billing, :sales_receipt]
	enum event_type: [:created, :updated, :deleted, :recreated]
end