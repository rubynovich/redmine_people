class AddLeaderToPerson < ActiveRecord::Migration
  def change
    add_column :users, :leader_id, :integer unless column_exists?(:users, :leader_id)
  end
end
