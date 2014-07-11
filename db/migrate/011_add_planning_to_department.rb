class AddPlanningToDepartment < ActiveRecord::Migration
  def self.up
    add_column :departments, :confirmer_id, :integer
  end

  def self.down
    remove_column :departments, :confirmer_id
  end
end
