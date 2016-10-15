class CreateAdmirals < ActiveRecord::Migration[5.0]
  def change
    create_table :admirals do |t|
      # OmniAuth から渡される uid
      # 数値だが string として渡されるため、そのまま保存する
      t.string  :twitter_uid,      :null => false,  :limit => 32

      # OmniAuth から渡される nickname
      # 現在の上限は 15 文字だが、余裕を見て上限は 32 とする
      t.string  :twitter_nickname, :null => false,  :limit => 32

      t.timestamps

      t.index :twitter_uid, :unique => true
    end
  end
end
