# 艦娘カードの所有率の集計を行うバッチです。
# 実行方法は以下の通りです。-e オプションを指定しない場合は、development で実行されます。
# rails runner ShipCardOwnershipBatch.execute -e (development|production)
class ShipCardOwnershipBatch
  def self.execute
    # レポートの生成時刻を記録
    reported_at = Time.current

    Rails.logger.info("Ship Card Ownership Batch started")

    begin
      # バッチ実行時のアクティブユーザ数を数える
      # 1回以上、艦娘図鑑ファイルをアップロードしているユーザを、アクティブユーザと見なす
      # SELECT count(distinct admiral_id) FROM ship_card_timestamps;
      no_of_active_users = ShipCardTimestamp.select(:admiral_id).distinct.count

      # バッチ実行時の各カードの枚数を数える
      # SELECT book_no, card_index, count(*) AS no_of_owners FROM ship_cards GROUP BY book_no, card_index;
      ship_cards = ShipCard.select('book_no, card_index, COUNT(*) AS no_of_owners').group(:book_no, :card_index)

      # 3. 計測結果を ship_card_ownerships テーブルに格納する
      ShipCardOwnership.transaction do
        ship_cards.each do |card|
          ShipCardOwnership.create!(
              :book_no => card.book_no,
              :card_index => card.card_index,
              :no_of_owners => card.no_of_owners,
              :no_of_active_users => no_of_active_users,
              :reported_at => reported_at,
          )
        end
      end

      Rails.logger.info("Ship Card Ownership Batch finished successfully")
    rescue => e
      Rails.logger.error("Ship Card Ownership Batch failed")
      Rails.logger.error(e)
    end

    # バッチのログは、明示的に flush を呼び出さないと、ファイルに書き出されない
    Rails.logger.flush
  end
end
