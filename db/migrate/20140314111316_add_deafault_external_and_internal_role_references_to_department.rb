class AddDeafaultExternalAndInternalRoleReferencesToDepartment < ActiveRecord::Migration

  def self.up
    add_column :departments, :default_internal_role_id, :integer unless column_exists?(:departments, :default_internal_role_id)
  end

  def self.down
    remove_column :departments, :default_internal_role_id if column_exists?(:departments, :default_internal_role_id)
  end

end
