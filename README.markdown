Name
====

lua-resty-setcookie - This library parse resp "set-cookie" for OpenResty.

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
    lua_package_path "/path/to/lua-resty-setcookie/lib/?.lua;;";

    server {
        location /t {
            proxy_pass http://www.vislee.com;

            header_filter_by_lua_block {
                local setck = require "resty.setcookie"
                local cookie = setck:new()
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

[Back to TOC](#table-of-contents)


get
---
`syntax: cookie_tab = cookie_obj:get(key)`

[Back to TOC](#table-of-contents)

get_all
-------
`syntax: field_tab = cookie_obj:get_all()`

[Back to TOC](#table-of-contents)

del
---
`syntax: old_cookie_tab = cookie_obj:del(key)`

[Back to TOC](#table-of-contents)


set
---
`syntax: old_cookie_tab = cookie_obj:set(text_cookie)`

[Back to TOC](#table-of-contents)


set_cookie
----------
`syntax: cookie_obj:set_cookie()`

[Back to TOC](#table-of-contents)


Authors
=======

wenqiang li(vislee)

[Back to TOC](#table-of-contents)


