class AddCfoToUser < ActiveRecord::Migration
  def change
    add_column :users, :cfo_id, :integer
  end
end
