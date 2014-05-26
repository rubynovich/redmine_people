class AddCfoToUser < ActiveRecord::Migration
  def change
    add_column :users, :cfo_id, :integer unless column_exists?(:users, :cfo_id)
  end
end
