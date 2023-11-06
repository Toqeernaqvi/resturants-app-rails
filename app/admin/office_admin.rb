ActiveAdmin.register OfficeAdmin, as: 'OfficeAdmin' do
  belongs_to :company

  menu false
  config.batch_actions = false
  actions :list
end
