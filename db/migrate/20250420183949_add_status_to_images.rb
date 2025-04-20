class AddStatusToImages < ActiveRecord::Migration[8.0]
  def change
    add_column :images, :status, :integer, null: false, default: 0
  end
end
