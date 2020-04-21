require "csv"
require 'google/apis/civicinfo_v2'
require 'erb'
require 'Date'

puts "EventManager Initialized"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

# Way to skip the headers line
# lines = File.readlines '../event_attendees.csv'
# row_index = 0
# lines.each do |line|
#     row_index = row_index + 1
#     next if row_index == 1
#     columns = line.split(",")
#     name = columns[2]
#     p name
# end

# Same as the code up there
# lines = File.readlines "event_attendees.csv"
# lines.each_with_index do |line,index|
#   next if index == 0
#   columns = line.split(",")
#   name = columns[2]
#   puts name
# end

# Same as before
# contents = CSV.open "../event_attendees.csv", headers: true
# contents.each do |row|
#   name = row[2]
#   puts name
# end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def clean_phone_numbers(number)
  number = number.delete(' ').delete('.').delete('-').delete('(').delete(')')
  if number.length < 10
    return number = "Invalid Phone Number"
  elsif number.length > 10
    if number[0] == '1'
      number = number[1..number.length-1]
    end
  end

  if number.length == 10
    number = number.insert(0, '(').insert(4,')').insert(5, '-').insert(9, '-')
  end
end

def clean_datetime(reg_time)
  reg_time = DateTime.strptime(reg_time, '%m/%d/%y %k:%M')
  reg_hour = reg_time.hour
  reg_day = reg_time.wday
  return reg_day, reg_hour
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

contents = CSV.open "../event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

# More verbose way of accessing with headers and conversion to symbols
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = clean_phone_numbers(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  reg_day, reg_hour = clean_datetime(row[:regdate])

  form_letter = erb_template.result(binding)
  puts "Weekday: #{reg_day}"
  puts "Hour: #{reg_hour}"
  # save_thank_you_letter(id,form_letter)
end