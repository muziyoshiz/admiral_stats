class AdmiralPublication < ApplicationRecord
  belongs_to :admiral

  # 提督 ID
  validates :admiral_id,
            presence: true,
            uniqueness: true,
            numericality: {
                only_integer: true,
            }

  # 公開する提督名（自己申告）
  # 艦これアーケードの提督名と同じように、Admiral Stats でも提督名の重複を許す
  validates :name,
            presence: true,
            length: { maximum: 32 }

  # 公開 URL に含まれる文字列
  # twitter の nickname と同じく、半角の英数字およびアンダーバーのみを許可する
  # しかし、case-insensitive に比較して、すでに同じ URL を使っている提督がいる場合は許可しない
  # （MySQL のデータベースを utf8_general_ci で設定しているため、自動的にそうなる）
  URL_NAME_REGEX = /\A[a-zA-Z0-9_]+\z/
  validates :url_name,
            presence: true,
            uniqueness: true,
            length: { maximum: 32 },
            format: { with: URL_NAME_REGEX }

  # Twitter の nickname を公開するかどうか
  validates :opens_twitter_nickname,
            inclusion: { in: [true, false] }

  # 艦娘一覧を公開するかどうか
  validates :opens_ship_list,
            inclusion: { in: [true, false] }
end
