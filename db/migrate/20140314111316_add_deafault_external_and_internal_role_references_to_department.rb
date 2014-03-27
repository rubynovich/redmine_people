class AddDeafaultExternalAndInternalRoleReferencesToDepartment < ActiveRecord::Migration

  def self.up
    add_column :departments, :default_internal_role_id, :integer
    add_column :departments, :default_external_role_id, :integer
  end

  def self.down
    remove_column :departments, :default_internal_role_id
    add_column :departments, :default_external_role_id

  end

end
