class CreateSkynetObservers < ActiveRecord::Migration
  def change
    create_table :skynet_observers do |t|
      t.integer   :user_id
      t.timestamps
    end
  end
end
