class AddPlanningToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :no_planning, :boolean
    add_column :users, :time_confirm, :smallint
  end

  def self.down
    remove_column :users, :no_planning
    remove_column :users, :time_confirm
  end
end
