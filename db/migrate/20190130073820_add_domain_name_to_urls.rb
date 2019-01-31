class AddDomainNameToUrls < ActiveRecord::Migration[5.2]
  def change
    add_column :urls, :domain_name, :string
    add_index :urls, :domain_name
  end
end
