class AddSanitazedPhonesToUser < ActiveRecord::Migration

  def up

    add_column(:users, :sanitized_phones, :string) unless column_exists?(:users, :sanitized_phones)

    for user in User.all
      user.update_column(:sanitized_phones, (user.phone || '').gsub(/[-()\s]/, ''))
    end

  end

  def down
    remove_column(:users, :sanitized_phones) if column_exists?(:users, :sanitized_phones)
  end

end
