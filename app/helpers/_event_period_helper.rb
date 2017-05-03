# イベントおよび作戦（前段作戦・後段作戦）に基づくビュー表示に関するヘルパーです。
module EventPeriodHelper
  # 指定されたイベントおよび作戦へのリンクを返します。
  # 多段作戦でない場合は、作戦の部分を省略します
  def link_to_event_period(event, period, url_options = {})
    if event.multi_period?
      link_to event_period_to_text(event, period), {event_no: event.event_no, period: period }.merge(url_options)
    else
      link_to event_period_to_text(event, period), {event_no: event.event_no }.merge(url_options)
    end
  end

  # EventMaster および period のテキスト表現を返します。
  # 多段作戦の場合は、period = 0 の場合は「(前段作戦)」、1 の場合は「(後段作戦)」を後置します。
  # 多段作戦でない場合は、イベント名のみを返します。
  def event_period_to_text(event, period)
    if event.multi_period?
      period_name = (period == 0 ? '前段作戦' : '後段作戦')
      "#{event.event_name} #{period_name}"
    else
      event.event_name
    end
  end
end
