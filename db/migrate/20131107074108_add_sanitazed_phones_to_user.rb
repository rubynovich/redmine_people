class AddSanitazedPhonesToUser < ActiveRecord::Migration

  def change

    add_column(:users, :sanitized_phones, :string)

    for user in User.all
      user.sanitized_phones = (user.phone || '').gsub(/[-()\s]/, '')
      user.save
    end

  end

end
