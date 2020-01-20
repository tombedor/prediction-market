require "selenium-webdriver"
require 'csv'
# Need gem install this and also brew install geckodriver
driver = Selenium::WebDriver.for :firefox

# urls retrieved with: Array.join($('a[href]').map(function(i, n) { return $(n).attr('href')}), ';')
SITE = "https://www.predictit.org"
urls = File.read('urls.txt').split(';')

primaries = urls.filter {|url| url.include? 'Who-will-win'}
p_urls = primaries.map{|url| SITE + url}

TITLE_SCRIPT = "return $('.market-header-title-large__text')[0].innerHTML"
PRICES_SCRIPT = (<<-EOF).strip
return $.map($('.row.row-100.market-contract-horizontal-v2__row'), function(element) {name = $(element).find('.market-contract-horizontal-v2__title-text')[0].innerHTML;yesPrice = $(element).find('.button-price__price')[0].innerHTML;noPrice = $(element).find('.button-price__price')[1].innerHTML;return name + ',' + yesPrice + ',' + noPrice}).join(';')
EOF

HEADER = %w(source state candidate yes_price no_price date url)
CSV.open("data/predictit_output_#{Date.today}.csv", "w") do |csv|
	csv << HEADER
	p_urls[1..4].each do |url|
		puts "parsing #{url}"
		driver.navigate.to url
		sleep 10
		raw_prices = driver.execute_script(PRICES_SCRIPT)
		raw_title = driver.execute_script(TITLE_SCRIPT)
		state = raw_title.gsub("Who will win the 2020 ", "").gsub(/ Democratic.*/, "").downcase.gsub(' ', '-')

		raw_prices.split(";") do |row|
			candidate = row.split(",")[0].split()[-1]
			yes_price = row.split(",")[1].gsub("¢", "").to_f / 100
			no_price = row.split(",")[2].gsub("¢", "").to_f / 100
			csv << ["predictit", state, candidate, yes_price, no_price, Date.today, url]
		end
	end
end


