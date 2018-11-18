Name
====

lua-resty-respcookie - This library parse resp "set-cookie" and reset for OpenResty.

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Synopsis](#synopsis)
* [Methods](#methods)
    * [new](#new)
    * [get](#get)
    * [get_all](#get_all)
    * [del](#del)
    * [set](#set)
    * [set_cookie](#set_cookie)
* [Authors](#authors)


Status
======

This library is still under early development and is still experimental.

Synopsis
========
```lua
    lua_package_path "/path/to/lua-resty-respcookie/lib/?.lua;;";

    server {
        location /t {
            proxy_pass http://www.vislee.com;

            header_filter_by_lua_block {
                local respck = require "resty.respcookie"
                local cookie = respck:new()
                local ck, err = cookie:del("test")
                if err ~= nil then
                    ngx.log(ngx.ERR, err)
                end

                ck, err = cookie:set("foo=bar; path=/; readonly")
                if err ~= nil then
                    ngx.log(ngx.ERR, err)
                end
                cookie:set_cookie()
            }
        }
    }
```

Methods
=======

[Back to TOC](#table-of-contents)


new
---
`syntax: cookie_obj = new()`

Create a cookie object for current resp.

[Back to TOC](#table-of-contents)


get
---
`syntax: cookie_tab = cookie_obj:get(key)`

Get a single resp cookie value, does not exist returns nil.

[Back to TOC](#table-of-contents)

get_all
-------
`syntax: field_tab = cookie_obj:get_all()`

Get all resp cookie key/val_tab pairs in a lua table.

[Back to TOC](#table-of-contents)

del
---
`syntax: old_cookie_tab = cookie_obj:del(key)`

Delete a single resp cookie key/vals.

[Back to TOC](#table-of-contents)


set
---
`syntax: old_cookie_tab = cookie_obj:set(text_cookie)`

Set a single resp cookie.

[Back to TOC](#table-of-contents)


set_cookie
----------
`syntax: cookie_obj:set_cookie()`

Set cookie_obj to resp header 'Set-Cookie'.

[Back to TOC](#table-of-contents)


Authors
=======

wenqiang li(vislee)

[Back to TOC](#table-of-contents)


