use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

log_level('debug');

repeat_each(1);
plan tests => repeat_each() * (3 * blocks());

no_long_string();

run_tests();

__DATA__

=== TEST 1: cookie:add
--- http_config
    lua_package_path 'lib/?.lua;;';

    init_by_lua_block {
        require 'luacov.tick'
        jit.off()
    }

--- config
    location /t {
        content_by_lua_block {
            ngx.say("ok")
        }
        header_filter_by_lua_block {
            local respck = require "resty.respcookie"
            local cookie = respck:new()
            local ck, err = cookie:set("test=testcookie; path=/")
            if err ~= nil then
                ngx.log(ngx.ERR, err)
            end
            cookie:set_cookie()
        }
    }

--- request
GET /t
--- response_headers_like
set-cookie: test=testcookie; path=/
--- error_code: 200
--- no_error_log
[error]



=== TEST 2: cookie:set
--- http_config
    lua_package_path 'lib/?.lua;;';

    init_by_lua_block {
        require 'luacov.tick'
        jit.off()
    }

    server {
        listen 127.0.0.1:9082;

        location / {
            content_by_lua_block {
                ngx.header["set-cookie"] = {"test=test; path=/", "foo=bar; path=/"}
                ngx.say("ok")
            }
        }
    }

--- config
    location /t {
        proxy_pass http://127.0.0.1:9082/;

        header_filter_by_lua_block {
            local cjson = require "cjson.safe"
            local respck = require "resty.respcookie"
            local cookie = respck:new()
            local ck, err = cookie:set("test=testcookie; path=/")
            if err ~= nil then
                ngx.log(ngx.ERR, err)
            end
            ngx.log(ngx.INFO, "del cookie:", cjson.encode(ck))
            cookie:set_cookie()
        }
    }

--- request
GET /t
--- response_headers_like
set-cookie: test=testcookie; path=/, foo=bar; path=/
--- error_code: 200
--- no_error_log
[error]


=== TEST 3: cookie:del
--- http_config
    lua_package_path 'lib/?.lua;;';

    init_by_lua_block {
        require 'luacov.tick'
        jit.off()
    }

    server {
        listen 127.0.0.1:9082;

        location / {
            content_by_lua_block {
                ngx.header["set-cookie"] = {"test=test; path=/", "foo=bar; path=/"}
                ngx.say("ok")
            }
        }
    }

--- config
    location /t {
        proxy_pass http://127.0.0.1:9082/;

        header_filter_by_lua_block {
            local cjson = require "cjson.safe"
            local respck = require "resty.respcookie"
            local cookie = respck:new()
            local ck, err = cookie:del("test")
            if err ~= nil then
                ngx.log(ngx.ERR, err)
            end
            ngx.log(ngx.INFO, "del cookie:", cjson.encode(ck))
            cookie:set_cookie()
        }
    }

--- request
GET /t
--- response_headers_like
set-cookie: foo=bar; path=/
--- error_code: 200
--- no_error_log
[error]



=== TEST 4: cookie:get
--- http_config
    lua_package_path 'lib/?.lua;;';

    init_by_lua_block {
        require 'luacov.tick'
        jit.off()
    }

    server {
        listen 127.0.0.1:9082;

        location / {
            content_by_lua_block {
                ngx.header["set-cookie"] = {"test=test; path=/; http", "foo=bar; path=/"}
                ngx.say("ok")
            }
        }
    }

--- config
    location /t {
        proxy_pass http://127.0.0.1:9082/;

        header_filter_by_lua_block {
            local cjson = require "cjson.safe"
            local respck = require "resty.respcookie"
            local cookie = respck:new()
            local ck = cookie:get("test")
            for k, v in ipairs(ck) do
                ngx.log(ngx.INFO, k, "====", v)
            end
            if ck == nil or type(ck) ~= "table" or ck["test"] ~= "test" or ck["path"] ~= "/" then
                ngx.log(ngx.ERR, "cookie get error")
            end
        }
    }

--- request
GET /t
--- response_headers_like
set-cookie: test=test; path=/; http, foo=bar; path=/
--- error_code: 200
--- no_error_log
[error]


=== TEST 5: cookie:get_all
--- http_config
    lua_package_path 'lib/?.lua;;';

    init_by_lua_block {
        require 'luacov.tick'
        jit.off()
    }

    server {
        listen 127.0.0.1:9082;

        location / {
            content_by_lua_block {
                ngx.header["set-cookie"] = {"test=test; path=/; domain=test.com; HttpOnly; secure", "foo=bar; path=/"}
                ngx.say("ok")
            }
        }
    }

--- config
    location /t {
        proxy_pass http://127.0.0.1:9082/;

        header_filter_by_lua_block {
            local cjson = require "cjson.safe"
            local respck = require "resty.respcookie"
            local cookie = respck:new()
            local field = cookie:get_all()
            local test = field["test"]
            if test == nil or test["domain"] ~= "test.com" or test[1] ~= "HttpOnly" then
                ngx.exit(ngx.HTTP_FORBIDDEN)
            end
            local foo = field["foo"]
            if foo == nil or foo["foo"] ~= "bar" then
                ngx.exit(ngx.HTTP_FORBIDDEN)
            end
        }
    }

--- request
GET /t
--- response_headers_like
set-cookie: test=test; path=/; domain=test.com; HttpOnly; secure, foo=bar; path=/
--- error_code: 200
--- no_error_log
[error]