require 'mechanize'
require 'csv'

mechanize = Mechanize.new
# はじめに検索して、お店一覧がでてくるときのurl
# 豊洲駅: https://tabelog.com/tokyo/A1313/A131307/R6850/rstLst/?vs=1&sa=%E8%B1%8A%E6%B4%B2&sk=&lid=hd_search1&vac_net=&svd=20170518&svt=1900&svps=2&hfc=1&sw=
# 世田谷区: https://tabelog.com/tokyo/C13112/rstLst/?vs=1&sa=%E4%B8%96%E7%94%B0%E8%B0%B7%E5%8C%BA&sk=&lid=top_navi1&vac_net=&svd=20170518&svt=1900&svps=2&hfc=1&sw=
# 杉並区: https://tabelog.com/tokyo/C13115/rstLst/?vs=1&sa=%E6%9D%89%E4%B8%A6%E5%8C%BA&sk=&lid=hd_search1&vac_net=&svd=20170518&svt=1900&svps=2&hfc=1&sw=
next_url = 'https://tabelog.com/tokyo/C13115/rstLst/?vs=1&sa=%E6%9D%89%E4%B8%A6%E5%8C%BA&sk=&lid=hd_search1&vac_net=&svd=20170518&svt=1900&svps=2&hfc=1&sw='

# お店を表すStruct
# 参照: http://d.hatena.ne.jp/m-kawato/20091214/1260754176
Restaurant = Struct.new(:name, :url, :phone)
# この配列の中にお店の情報を入れていく
restaurants = []

puts "Scraping name and url"

loop do
  # mechanizeを利用してページを所得
  toshyu_page = mechanize.get(next_url)
  # お店の名前とURlがある<a>タグを探して全て、所得した後それを配列に保存していく
  toshyu_page.search('.list-rst__rst-name-target.cpy-rst-name').each do |a|
    # a.inner_text -> お店の名前
    # a[:href] -> url
    restaurants << Restaurant.new(a.inner_text, a[:href])
  end
    # 次のurlを一覧のurlを所得
    # &. という記法は、ruby 2.3からなのでそれ以下だとエラーになってしまう。
    # 参照: http://qiita.com/jnchito/items/dedb3b889ab226933ccf#%E5%AD%90%E3%81%A9%E3%82%82%E3%81%AE%E3%82%AA%E3%83%96%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E3%81%8C%E5%AD%98%E5%9C%A8%E3%81%99%E3%82%8B%E5%A0%B4%E5%90%88%E3%81%AB%E3%81%AE%E3%81%BF%E3%81%9D%E3%81%AE%E3%83%97%E3%83%AD%E3%83%91%E3%83%86%E3%82%A3%E3%82%84%E3%83%A1%E3%82%BD%E3%83%83%E3%83%89%E3%82%92%E5%91%BC%E3%81%B3%E5%87%BA%E3%81%97%E3%81%A6%E6%9D%A1%E4%BB%B6%E3%82%92%E7%A2%BA%E8%AA%8D%E3%81%99%E3%82%8B%E3%82%92%E3%81%B2%E3%81%A8%E3%81%A4%E3%81%AEif%E3%81%A7%E6%9B%B8%E3%81%8F
    next_url = toshyu_page.search('.page-move__target.page-move__target--next').first&.get_attribute('href')
    print '.'
    break unless next_url
end

puts "\nScraping phone"

# 所得した全てのお店のurlにアクセスして電話番号を所得する。
restaurants.each do |restaurant|
  restaurant.phone = mechanize.get(restaurant.url).search('.rstinfo-table__tel-num.rstinfo-table__tel-num--main').inner_text
  print '.'
end

CSV.open('gurunabi-suginami.csv', 'w') do |csv|
  csv << ['name', 'url', 'phone']
  restaurants.each { |restaurant| csv << [restaurant.name, restaurant.url, restaurant.phone] }
end