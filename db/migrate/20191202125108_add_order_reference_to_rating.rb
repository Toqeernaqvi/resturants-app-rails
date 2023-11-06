class AddOrderReferenceToRating < ActiveRecord::Migration[5.1]
  def change
    add_reference :ratings, :order, foreign_key: true, after: :user_id
    add_reference :ratings, :runningmenu, foreign_key: true, after: :user_id
  end
end
