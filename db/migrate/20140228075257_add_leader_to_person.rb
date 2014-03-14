class AddLeaderToPerson < ActiveRecord::Migration
  def change
    add_column :users, :leader_id, :integer
  end
end
