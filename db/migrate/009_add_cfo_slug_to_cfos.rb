class AddCfoSlugToCfos < ActiveRecord::Migration
  def change
    add_column :cfos, :cfo_slug, :string, limit: 50 unless column_exists?(:cfos, :cfo_slug)
    add_index :cfos, :cfo_slug, unique: true unless index_exists?(:cfos, :cfo_slug)
  end
end
