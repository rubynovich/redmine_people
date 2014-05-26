class AddCfoSlugToCfos < ActiveRecord::Migration
  def change
    add_column :cfos, :cfo_slug, :string unless column_exists?(:cfos, :cfo_slug)
  end
end
