class CreateCfo < ActiveRecord::Migration
  def change
    create_table :cfos do |t|
    	t.text :cfo
    end
  end
end
