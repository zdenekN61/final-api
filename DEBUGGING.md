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

     curl -i -H 'UserName: FIN'  -H "Accept: application/json" \
       -H 'AuthenticationToken: secret' \
       -H  "Content-Type: application/json" \
       -X POST -d @stash-payload.json \
       http://localhost:9292/requests

Where `stash-payload.json` contains:

     {
       "owner_name": "FIN",
       ".travis.yml": {
         "language": "bash",
         "script": "echo 'it works!'; sleep 10; echo 'finish!'"
       },


       "provider": "stash",


       "repository":{
         "slug":"test-repo",
         "name":"test-repo",
         "project":{
            "key":"FIN",
            "name":"FINAL-CI",
            "description":"Test framework based on travis-ci",
            "public":true,
            "type":"NORMAL"
         },
         "public":true
       },
       "refChange": {
         "refId":"refs/heads/master",
         "fromHash":"26889fb199985390da9c668d1399702940c44132",
         "toHash":"08328b76d12e956d96e5e87c1fd7cf34265828ef",
         "type":"UPDATE"
       }
     }

