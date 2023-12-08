With the `Content-Security-Policy` header you can control which scripts are
allowed to run on a page; if you're not using this header then you can ignore
this page.

For the standard integration you’ll need to add the following:

    script-src  https://{{.CountDomain}}
    img-src     {{.SiteURL}}/count

The `script-src` is needed to load the `count.js` script, and the `img-src` is
needed to send pageviews to GoatCounter (which are loaded with a “tracking
pixel”).

Alternatively you can host the `count.js` script anywhere you want, or include
it directly in your page. See [count.js hosting](/code/countjs-host).
