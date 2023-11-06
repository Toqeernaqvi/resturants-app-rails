ActiveAdmin.register Sequence do
  menu parent: 'Schedulers', priority: 2
  config.batch_actions = false
  actions :all, :except => :destroy

  permit_params do
    permitted = [
      :name,
      :restaurants_served,
      :menu_type,
      labels_seqs_attributes: [
        :id,
        :title,
        :_destroy,
        cuisines_sequences_attributes: [
          :id,
          :position,
          :labels_seq_id,
          :cuisineslist_id,
          :_destroy
        ]
      ]
    ]
  end
  action_item only: [:index] do
    link_to 'Cuisine Lists', admin_cuisineslists_path
  end
  index do
    column :id
    column :name
    column :menu_type
    column :status do |sequence|
      if sequence.active?
        status_tag( :active )
      else
        status_tag( :deleted )
      end
    end
    actions do |sequence|
      if sequence.active?
        item('Delete', delete_admin_sequence_path(sequence.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_sequence_path(sequence.id) , class: [:member_link, :active_btn])
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name#, label: false
      if f.object.new_record?
        f.input :restaurants_served#, label: false
        f.input :menu_type
      else
        f.input :restaurants_served, input_html: { readonly: true }
        f.input :menu_type, input_html: { disabled: true }
      end
      f.semantic_errors :base
      unless f.object.new_record?
        f.has_many :labels_seqs, heading: nil, allow_destroy: false, new_record: false do |ls|
          if ls.object.cuisines_sequences.blank?
            ls.object.cuisines_sequences.build()
          end
          ls.input :title, input_html: { readonly: true}, label: false
          ls.has_many :cuisines_sequences, heading: nil, allow_destroy: true, :sortable => :position, new_record: '+' do |rs|
            rs.input :id, as: :hidden
            rs.input :position, as: :hidden
            # rs.input :cuisineslist_id, as: :select, collection: Cuisineslist.active, label: rs.object.position.to_s, required: false
            rs.input :cuisineslist_id, as: :search_select, label: rs.object.position.to_s, required: false, url: cuisineslists_admin_sequences_path, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc'
          end
        end  
      end  
      f.actions
    end
  end

  show do
    attributes_table do
      row :name
      row :restaurants_served
      row :menu_type
    end
    panel "" do
      table_for sequence.cuisines_sequences.order(:position) do
        column :title
        column :position
        column :cuisineslist
      end
    end
  end

   member_action :delete, method: :get do
    sequence = Sequence.find(params[:id])
    if sequence.active?
      sequence.deleted!
      redirect_to admin_sequences_path, notice: "Sequence has been successfully deleted"
    end
  end

  member_action :active, method: :get do
    sequence = Sequence.find(params[:id])
    if sequence.deleted?
      sequence.active!
      redirect_to admin_sequences_path, notice: "Sequence haas been successfully active"
    end
  end

  collection_action :cuisineslists, method: :get do
    cuisineslist = Cuisineslist.active.where("menu_type = #{Cuisineslist.menu_types[params[:menu_type]]} AND (name ILIKE :prefix)", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%")
    render json: cuisineslist.collect {|cl| {:id => cl.id, :name => cl.name} }
  end

  filter :name

  controller do
    def create
      create! {|success, failure|
        success.html { redirect_to edit_admin_sequence_path(resource)}
      }
    end
  end
  
end