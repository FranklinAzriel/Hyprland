#!/bin/bash

# Replace with your actual API key
API_KEY="$1"
country="$2"
city="$3"

# Fetch weather data from OpenWeatherMap API
api_url="https://api.openweathermap.org/data/2.5/weather?q=${city},${country}&appid=${API_KEY}&units=metric"
json_data=$(curl -s "$api_url")

# Check if the API request was successful
if echo "$json_data" | jq -e '.cod == 401' > /dev/null; then
  output=$(jq -n \
    --arg text "Invalid API key" \
    --arg tooltip "Please check your API Key" \
    '{text: $text, tooltip: $tooltip}')
  echo $output
  exit 1
fi

if echo "$json_data" | jq -e '.cod == 404' > /dev/null; then
  output=$(jq -n \
    --arg text "Invalid city/county" \
    --arg tooltip "Please check the city name and try again" \
    '{text: $text, tooltip: $tooltip}')
  echo $output
  exit 1
fi

if echo "$json_data" | jq -e '.cod == 429' > /dev/null; then
  output=$(jq -n \
    --arg text "Rate limited" \
    --arg tooltip "Please try again later" \
    '{text: $text, tooltip: $tooltip}')
  echo $output
  exit 1
fi

if echo "$json_data" | jq -e '.cod >= 500 and .cod <= 504' > /dev/null; then
  output=$(jq -n \
    --arg text "Internal server error" \
    --arg tooltip "Please try again later" \
    '{text: $text, tooltip: $tooltip}')
  echo $output
  exit 1
fi

if echo "$json_data" | jq -e '.cod != 200' > /dev/null; then
  error_message=$(echo "$json_data" | jq -r '.message')
  output=$(jq -n \
    --arg text "Error" \
    --arg tooltip "$error_message" \
    '{text: $text, tooltip: $tooltip}')
  echo $output
  exit 1
fi

# Extract data using jq
text=$(echo $json_data | jq -r '.weather[0].main')
temperature=$(echo $json_data | jq -r '.main.temp')
humidity=$(echo $json_data | jq -r '.main.humidity')
pressure=$(echo $json_data | jq -r '.main.pressure')

if [ $text == "clear sky" ]; then
  text="Clear Sky "
fi

if [ $text == "Rain" ]; then
  text="Rain "
fi

# Format output
output=$(jq -n \
  --arg text "$text" \
  --arg tooltip "Temperature: ${temperature} °C, Humidity: ${humidity}%, Pressure: ${pressure} hPa" \
  '{text: $text, tooltip: $tooltip}')

# Print the output
echo $output
