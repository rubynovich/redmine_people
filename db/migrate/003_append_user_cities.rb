class AppendUserCities < ActiveRecord::Migration
  def self.up
    add_column :users, :city, :smallint, :default => 0
  end

  def self.down
    remove_column :users, :city
  end

end
