class CreateCfo < ActiveRecord::Migration
  def change
    create_table :cfos do |t|
    	t.text :cfo
    end unless table_exists?(:cfos)
  end
end
