require "selenium-webdriver"
require 'csv'
# Need gem install this and also brew install geckodriver
driver = Selenium::WebDriver.for :firefox

SITE = "https://projects.fivethirtyeight.com/2020-primary-forecast/"
STATES = File.read('states.txt').split("\n").map{|s| s.downcase.gsub(" ", "-")}
CANDIDATES = "Sanders,Warren,Biden,Buttigieg,Bloomberg,Klobuchar,Steyer,Yang,Gabbard,Booker,Harris,Delaney,Patrick,Castro,Bullock,Williamson,Bennet,Sestak".split(",")
CSV.open("data/538_output_#{Date.today}.csv", "w") do |csv|
	HEADER = %w(source state candidate yes_price no_price date url)
        puts "scraping #{STATES.count} urls"
	csv << HEADER
	STATES.each do |state|
		url = SITE + state
		puts "scraping #{url}"
		driver.navigate.to(url)
		sleep 10
		driver.find_element(:class, "candidate-select").find_elements(tag_name: "option").each do |option|
			option.click
			sleep 3
			name = option.attribute("innerText")
			puts name
			next if driver.find_element(class: "robo-text").attribute("innerText").include?("is no longer actively campaigning")
			odds = driver.find_elements(tag_name: 'c')[0].attribute("innerText")[1...-2]
			yes_price = odds.to_f / 100
			no_price = 1 - yes_price
			csv << ['538', state, name, yes_price, no_price, Date.today, url]
		end
	end
end
