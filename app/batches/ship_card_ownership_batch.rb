# 艦娘カードの所有率の集計を行うバッチです。
# 実行方法は以下の通りです。-e オプションを指定しない場合は、development で実行されます。
# rails runner ShipCardOwnershipBatch.execute -e (development|production)
class ShipCardOwnershipBatch
  def self.execute
    # レポートの生成時刻を記録
    reported_at = Time.current

    Rails.logger.info("Ship Card Ownership Batch started")

    # 全提督を対象とした集計
    begin
      # バッチ実行時のアクティブユーザ数を数える
      # 1回以上、艦娘図鑑ファイルをアップロードしているユーザを、アクティブユーザと見なす
      # SELECT count(distinct admiral_id) FROM ship_card_timestamps;
      no_of_active_users = ShipCardTimestamp.select(:admiral_id).distinct.count

      # バッチ実行時の各カードの枚数を数える
      # SELECT book_no, card_index, count(*) AS no_of_owners FROM ship_cards GROUP BY book_no, card_index;
      ship_cards = ShipCard.select('book_no, card_index, COUNT(*) AS no_of_owners').group(:book_no, :card_index)

      # 計測結果を ship_card_ownerships テーブルに格納する
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

      Rails.logger.flush
      return
    end

    # 限定海域の参加者のみを対象とした集計
    begin
      # 集計対象の限定海域があるかどうかを調べる（通常は、0〜1件しか該当しないはず）
      # 開始日の3日後から集計開始し、終了日の2日後明朝まで集計処理を実行する
      # 10/27(木) 7:00 〜 11/25(金) 23:59 なら、10/30(日) 3:00 に最初の集計、11/27(日) 3:00 に最後の集計
      t = Time.current - 2.days
      events = EventMaster.where('started_at <= ? AND ? < ended_at', t, t)

      events.each do |event|
        Rails.logger.info("Ship Card Ownership (Event No. #{event.event_no}) Batch started")

        # バッチ実行時のアクティブユーザ数を数える
        # 限定海域の開催期間中に、1回以上、艦娘図鑑ファイルをアップロードしているユーザを、アクティブユーザと見なす
        # 開催終了後にエクスポートすることも考えて、終了時刻には猶予をもたせる
        # SELECT count(distinct admiral_id) FROM ship_card_timestamps WHERE exported_at >= started_at;
        no_of_active_users = ShipCardTimestamp.select(:admiral_id).where('exported_at >= ?', event.started_at).distinct.count

        # 上記のアクティブユーザの各カードの枚数を数える
        ship_cards = ShipCard.find_by_sql(
            [
                'SELECT book_no, card_index, COUNT(*) AS no_of_owners FROM ship_cards sc WHERE EXISTS ' +
                    '(SELECT * FROM ship_card_timestamps sct WHERE sc.admiral_id = sct.admiral_id AND sct.exported_at >= ?) ' +
                    'GROUP BY book_no, card_index',
                event.started_at
            ]
        )

        # 計測結果を event_ship_card_ownerships テーブルに格納する
        EventShipCardOwnership.transaction do
          ship_cards.each do |card|
            EventShipCardOwnership.create!(
                :event_no => event.event_no,
                :book_no => card.book_no,
                :card_index => card.card_index,
                :no_of_owners => card.no_of_owners,
                :no_of_active_users => no_of_active_users,
                :reported_at => reported_at,
            )
          end
        end

        Rails.logger.info("Ship Card Ownership (Event No. #{event.event_no}) Batch finished successfully")
      end
    rescue => e
      Rails.logger.error("Ship Card Ownership (Event) Batch failed")
      Rails.logger.error(e)
    end

    # バッチのログは、明示的に flush を呼び出さないと、ファイルに書き出されない
    Rails.logger.flush
  end
end
