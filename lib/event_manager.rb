require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode zipcode
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number number  # Assignment: Clean Phone Numbers
  number.delete! '^0-9'
  if number.length == 10
    number
  elsif number.length == 11
    number[1..-1] if number[0] == 1
  end
end

def find_highest_hours reg_date  # Assignment: Time Targeting
  records_per_hour = Hash.new 0
  reg_date.each do |date|
    time = Time.strptime date, "%y/%d/%m %H:%M"
    records_per_hour[time.hour] += 1
  end
  #   reverse sorting                           array of hashes
  records_per_hour.sort {|a,b| b[1] <=> a[1]}.map {|arr| {arr[0] => arr[1]}}
end

def find_highest_days reg_date  # Assigment: Day of the Week Targeting
  records_per_day = Hash.new 0
  days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday',
          'Thursday', 'Friday', 'Saturday']

  reg_date.each do |date|
    date = Time.strptime date, "%y/%d/%m %R"
    records_per_day[days[date.wday]] += 1
  end
  #   reverse sorting                        array of hashes
  records_per_day.sort {|a,b| b[1] <=> a[1]}.map {|arr| {arr[0] => arr[1]}}
end

# I decided to merge two methods!!
def find_highest reg_date, days=false  # hours is the default option...
  records = Hash.new 0

  reg_date.each do |date|
    time = Time.strptime date, "%y/%d/%m %H:%M"
    key = days ? time.strftime('%A') : time.hour
    records[key] += 1
  end
  #   reverse sorting             array of hashes
  records.sort {|a, b| b[1] <=> a[1]}.map {|c| {c[0] => c[1]}}
end

def legislators_by_zipcode zipcode
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir 'output' unless Dir.exist? 'output'
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )

contents_full = CSV.table(
    'event_attendees_full.csv',
    headers: true,
    header_converters: :symbol
  )

contents.each do |row|
  id = row[0]  # no header for id, only an empty field
  name = row[:first_name]

  puts clean_phone_number row[:homephone]

  zipcode = clean_zipcode row[:zipcode]
  legislators = legislators_by_zipcode zipcode

  form_letter = erb_template.result binding

  save_thank_you_letter(id, form_letter)
  puts form_letter
end

#puts 'Assignment: clean phone numbers'
#contents.each do |row|
#  puts "#{row[:first_name]} ... #{clean_phone_number row[:homephone]}"
#end

puts 'Assignment: time targeting'
highest_hours = find_highest_hours contents_full[:regdate]
puts highest_hours
print 'Most common hour: '
highest_hours[0].each {|hour, records| puts "#{hour} with #{records} records"}

puts 'Assignment: day targeting'
highest_days = find_highest_days contents_full[:regdate]
puts highest_days
print 'Most common day: '
highest_days[0].each {|day, records| puts "#{day} with #{records} records"}
