# Description
#   Grabs the current forecast from Dark Sky.
#   Powered by Dark Sky: https://darksky.net/poweredby/
#
# Dependencies
#   None
#
# Configuration
#   HUBOT_DARK_SKY_API_KEY
#   HUBOT_DARK_SKY_DEFAULT_LOCATION
#   HUBOT_DARK_SKY_UNITS (optional - us, si, ca, or uk)
#
# Commands:
#   hubot weather - Get the weather for HUBOT_DARK_SKY_DEFAULT_LOCATION
#   hubot weather <location> - Get the weather for <location>
#
# Notes:
#   If HUBOT_DARK_SKY_DEFAULT_LOCATION is blank, weather commands without a location will be ignored
#
# Author:
#   kyleslattery
module.exports = (robot) ->
  robot.respond /weather ?(.+)?( on (mon|tue|wed|thu|fri|sat|sun)day)?/i, (msg) ->
    location = msg.match[1] || process.env.HUBOT_DARK_SKY_DEFAULT_LOCATION
    dayOfWeek = msg.match[3];
    return if not location

    if location == "about"
      msg.send "<https://darksky.net/poweredby/|Powered by Darksky>"
    else if location == "help"
      response = "Commands\n";
      response += "`bot weather` - Get the weather for the default location\n";
      response += "`bot weather <location>` - Get the weather for <location>\n";
      response += "`bot weather about` - About the DarkSky API\n";
      response += "day of week text: #{dayOfWeek}";
      msg.send response
    else 
      googleurl = "http://maps.googleapis.com/maps/api/geocode/json"
      q = sensor: false, address: location
      msg.http(googleurl)
        .query(q)
        .get() (err, res, body) ->
          result = JSON.parse(body)

          if result.results.length > 0
            lat = result.results[0].geometry.location.lat
            lng = result.results[0].geometry.location.lng
            darkSkyMe msg, lat, lng, dayOfWeek, (darkSkyText) ->
              response = "Weather for #{result.results[0].formatted_address}. #{darkSkyText}"
              msg.send response
          else
            msg.send "Couldn't find #{location}"

darkSkyMe = (msg, lat, lng, dayOfWeek, callback) ->
  url = "https://api.darksky.net/forecast/#{process.env.HUBOT_DARK_SKY_API_KEY}/#{lat},#{lng}"
  dateToGet = getDate dayOfWeek
  if dateToGet
    url += "," + dateToGet
  if process.env.HUBOT_DARK_SKY_UNITS
    url += "?units=#{process.env.HUBOT_DARK_SKY_UNITS}"
  msg.http(url)
    .get() (err, res, body) ->
      result = JSON.parse(body)

      if result.error
        callback "#{result.error}"
        return

      isFahrenheit = process.env.HUBOT_DARK_SKY_UNITS == "us"
      if isFahrenheit
        fahrenheit = result.currently.temperature
        celsius = (fahrenheit - 32) * (5 / 9)
        celsius = celsius.toFixed(2)
      else
        celsius = result.currently.temperature
        fahrenheit = celsius * (9 / 5) + 32
        fahrenheit = fahrenheit.toFixed(2)
      response = "Currently: #{result.currently.summary} (#{fahrenheit}°F/"
      response += "#{celsius}°C).\n"

      if dateToGet
        formattedDate = parseTime result.hourly.time
        response += "#Weather for #{formattedDate}: #{result.hourly.summary}"
      else      
        response += "Today: #{result.hourly.summary}\n"
        response += "Coming week: #{result.daily.summary}"
      callback response

getDate = (dayOfWeek) ->
  if dayOfWeek
    #dayOfWeek = dayOfWeek.toLower    
    return "+2400"
  else 
    return null;

parseTime = (unixTime) ->
  return new Date(unixTime)