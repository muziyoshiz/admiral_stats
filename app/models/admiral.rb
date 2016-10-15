class Admiral < ApplicationRecord
  # OmniAuth から渡される uid
  validates :twitter_uid,
            presence: true,
            length: { minimum: 1, maximum: 32 }

  # OmniAuth から渡される nickname
  validates :twitter_nickname,
            presence: true,
            length: { minimum: 1, maximum: 32 }

  def self.find_or_create_from_auth(auth)
    # Provider が Twitter 以外の場合は拒否
    if (auth[:provider] != 'twitter')
      logger.error("Unsupported OmniAuth provider: #{auth[:provider]}")
      return nil
    end

    logger.debug("OmniAuth provider: #{auth[:provider]}, uid: #{auth[:uid]}, nickname: #{auth[:info][:nickname]}")
    self.find_or_create_by(twitter_uid: auth[:uid]) do |admiral|
      admiral.twitter_nickname = auth[:info][:nickname]
    end
  end
end
