# README
Url-Shortener Api 
This README would normally document whatever steps are necessary to get the
application up and running.

* Ruby version ~>2.3.7
Get request: fetch Long url using short_url
How to implement on postman:
GET localhost:3000/long_url?send params here in key value pair .json
Example: GET localhost:3000/long_url?short_url=b59313
          OUTPUT : {"long_url":"https://www.w3schools.com/js/"}
POST requesst:generate short_url using long_url
Example: POST localhost:3000/url_shorteners.json
         Body : {"long_url":"https://www.w3schools.com/js/"}
         Ouput: {"short_url":"b59313"}
A panel with login feature,count of newly generated short_url in a day and elastic search to search long_url from short_url

Clone/download 
run bundle install
rake db:migrate

And it's good to go
      




* ...
