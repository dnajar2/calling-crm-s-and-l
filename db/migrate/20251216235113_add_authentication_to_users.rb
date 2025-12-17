class AddAuthenticationToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :password_digest, :string
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :refresh_token, :string
    add_column :users, :email_verified, :boolean, default: false
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime

    add_index :users, :email, unique: true
    add_index :users, [:provider, :uid], unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
