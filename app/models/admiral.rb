class Admiral < ApplicationRecord
  # OmniAuth から渡される uid
  validates :twitter_uid,
            presence: true,
            length: { minimum: 1, maximum: 32 }

  # OmniAuth から渡される nickname
  validates :twitter_nickname,
            presence: true,
            length: { minimum: 1, maximum: 32 }

  # 与えられた twitter uid の提督がすでに存在するか調べて、存在しなければ新規作成します。
  # また、すでに存在する提督の twitter nickname が変更されている場合は更新します。
  def self.find_or_create_from_auth(auth)
    # Provider が Twitter 以外の場合は拒否
    if (auth[:provider] != 'twitter')
      logger.error("Unsupported OmniAuth provider: #{auth[:provider]}")
      return nil
    end

    logger.debug("OmniAuth provider: #{auth[:provider]}, uid: #{auth[:uid]}, nickname: #{auth[:info][:nickname]}")

    admiral = self.find_by_twitter_uid(auth[:uid])

    begin
      if admiral
        if admiral.twitter_nickname != auth[:info][:nickname]
          admiral.update!(twitter_nickname: auth[:info][:nickname])
        end
      else
        admiral = self.create!(twitter_uid: auth[:uid], twitter_nickname: auth[:info][:nickname])
      end
    rescue => e
      logger.error("Failed to create or update Admiral: twitter_uid=#{auth[:uid]}, twitter_nickname=#{auth[:info][:nickname]}")
      logger.error(e)
      return nil
    end

    admiral
  end
end
