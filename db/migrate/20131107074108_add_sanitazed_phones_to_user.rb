class AddSanitazedPhonesToUser < ActiveRecord::Migration

  def up

    add_column(:users, :sanitized_phones, :string)

    for user in User.all
      user.update_column(:sanitized_phones, (user.phone || '').gsub(/[-()\s]/, ''))
    end

  end

  def down
    remove_column(:users, :sanitized_phones)
  end

end
