class CreateImages < ActiveRecord::Migration[8.0]
  def change
    create_table :images do |t|
      t.text :prompt
      t.text :keywords
      t.string :image_name

      t.timestamps
    end
  end
end
