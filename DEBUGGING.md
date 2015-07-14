Run console
-----------

     $: << 'lib'; require 'bundler/setup'; require 'final-api'; FinalAPI.setup
     require 'final-api/app'




Requests
--------

Get all requests for repository_id=1

     curl -i http://localhost:9292/requests?repository_id=1
     curl -i 'http://localhost:9292/requests?repository_id=1&limit=1'
     curl -i 'http://localhost:9292/requests?repository_id=1&oldthen=10' # older then represents repository_id

Get particular request

     curl -i http://localhost:9292/requests/7   # get request by Id
     curl -i http://localhost:9292/requests/354e62f878485e2301bce31c #
get request by jid

Schedule a request

     curl -i \
       -H 'UserName: lksv' \
       -H "Accept: application/json" \
       -H  "Content-Type: application/json" \
       -X POST -d @'../travis-listener/stash-payload.json' \
       http://localhost:4567/requests

