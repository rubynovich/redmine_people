class AddConfirmTypesToPerson < ActiveRecord::Migration
  def change
    add_column :users, :must_kgip_confirm, :boolean, :default => true
    add_column :users, :must_head_confirm, :boolean, :default => true
  end
end
