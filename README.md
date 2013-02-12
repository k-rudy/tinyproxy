Tiny Proxy
==========

Dead simple multithreaded HTTP proxy server with caching facilities

Running
-------
To run the server simply type:
```
  ruby server.rb
```
Then you need to adjust your browser/system proxy settings to connect
to localhost at 2000 port

Configuration
-------------
The following settings can be configured through `settings.yml`:

1. Proxy server port
2. Cache limit
3. Cacheable statuses
4. Cacheable content types

and some other minor options

Assumptions
-----------
1. Supports only GET verbs
2. Supports only HTTP requests

Known issues
------------

Has encoding issue for some websites. Unfortunately don't have time to
investigate and fix that.

Have fun!
