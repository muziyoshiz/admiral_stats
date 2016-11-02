// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require highcharts
//= require highcharts/highcharts-more

// チャート画像のダウンロード機能
//= require highcharts/modules/exporting
//= require highcharts/modules/offline-exporting

//= require_tree .

// DataTables のデフォルト設定
var ADMIRAL_STATS_DATATABLES_DEFAULT = {
  // 1ページに表示したいデータが多いため、デフォルトはページング無効とする
  "paging": false,
  "autoWidth": false,
  // 表示の日本語化
  "language": {
    "url": "//cdn.datatables.net/plug-ins/1.10.12/i18n/Japanese.json"
  },
};

// Highcharts で時系列データを表示する際のデフォルト設定
var ADMIRAL_STATS_HIGHCHARTS_DEFAULT = {
  exporting: {
    sourceHeight: 400,
    sourceWidth: 800,
  },
  chart: {
    type: 'line'
  },
  xAxis: {
    type: 'datetime',
    dateTimeLabelFormats: {
      second: '%H:%M:%S',
      minute: '%H:%M',
      hour: '%H:%M',
      day: '%m月%d日',
      week: '%m月%d日',
      month: '%Y-%m',
      year: '%Y'
    },
    title: {
      text: null
    }
  },
  tooltip: {
    dateTimeLabelFormats: {
      millisecond: "%m月%d日 %H:%M",
      second: "%m月%d日 %H:%M",
      minute: "%m月%d日 %H:%M",
      hour: "%m月%d日 %H:%M",
      day: "%Y年%m月%d日",
      week: "%Y年%m月%d日",
      month: "%Y-%m",
      year: "%Y"
    }
  },
}

// 指定した URL パラメータの値を取得します。
// http://stackoverflow.com/questions/19491336/get-url-parameter-jquery-or-how-to-get-query-string-values-in-js
var getUrlParameter = function getUrlParameter(sParam) {
  var sPageURL = decodeURIComponent(window.location.search.substring(1)),
    sURLVariables = sPageURL.split('&'),
    sParameterName,
    i;

  for (i = 0; i < sURLVariables.length; i++) {
    sParameterName = sURLVariables[i].split('=');

    if (sParameterName[0] === sParam) {
      return sParameterName[1] === undefined ? true : sParameterName[1];
    }
  }
};
