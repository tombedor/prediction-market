require "selenium-webdriver"
require 'csv'
# Need gem install this and also brew install geckodriver
driver = Selenium::WebDriver.for :firefox

SITE = "https://projects.fivethirtyeight.com/2020-primary-forecast/"
STATES = File.read('states.txt').split("\n").map{|s| s.downcase.gsub(" ", "-")}
CANDIDATES = "Sanders,Warren,Biden,Buttigieg,Bloomberg,Klobuchar,Steyer,Yang,Gabbard,Booker,Harris,Delaney,Patrick,Castro,Bullock,Williamson,Bennet,Sestak".split(",")
CSV.open("538_output.csv", "a") do |csv|
	HEADER = %w(state candidate percent_chance date url)
	csv << HEADER
	STATES.each do |state|
		url = SITE + state
		puts "scraping #{url}"
		driver.navigate.to(url)
		sleep 5
		driver.find_element(:class, "candidate-select").find_elements(tag_name: "option").each do |option|
			option.click
			sleep 1
			name = option.attribute("innerText")
			puts name
			next if driver.find_element(class: "robo-text").attribute("innerText").include?("is no longer actively campaigning")
			odds = driver.find_elements(tag_name: 'c')[0].attribute("innerText")[1...-2]
			csv << [state, name, odds, Date.today, url]
		end
	end
end
