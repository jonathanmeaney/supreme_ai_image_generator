class BackfillImageStatusComplete < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    say_with_time "Back‑filling existing images to status: complete" do
      # make sure AR knows about your new `status` column & enum
      Image.reset_column_information

      # this will generate SQL like
      #   UPDATE images SET status = 2;
      Image.update_all(status: :complete)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
