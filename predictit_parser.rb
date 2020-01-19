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

HEADER = %w(state candidate yes_price no_price url)
CSV.open("output.csv", "a") do |csv|
	csv << HEADER
	p_urls.each do |url|
		puts "parsing #{url}"
		driver.navigate.to url
		sleep 5
		raw_prices = driver.execute_script(PRICES_SCRIPT)
		raw_title = driver.execute_script(TITLE_SCRIPT)
		state = raw_title.gsub("Who will win the 2020 ", "").gsub(/ Democratic.*/, "")

		raw_prices.split(";") do |row|
			candidate = row.split(",")[0]
			yes_price = "0." + row.split(",")[1].gsub("¢", "")
			no_price = "0." + row.split(",")[2].gsub("¢", "")
			csv << [state, candidate, yes_price, no_price, url]
		end
	end
end

