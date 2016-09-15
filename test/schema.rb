ActiveRecord::Schema.define(:version => 0) do
  create_table :customers, :force => true do |t|
    t.string   :name
    t.string   :email
    t.string   :phone_number
  end

  add_index :customers, :email, unique: true
end
