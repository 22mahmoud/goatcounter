Session tracking
================

*2022 preface*: this document mostly served as a design document for when I
wrote the session tracking code back in 2019. It's not intended as an overview
of "all possible techniques one could use in $current_year"; the examination of
existing solutions is likely incomplete, and sometimes probably outdated as
platforms evolve.

In short: I don't keep it updated.

---


"Session tracking" allows more advanced tracking than just the "pageview"
counter we have now. A "session" is a single browsing session people have on a
website.

Right now, every pageview shows up as-is in the dashboard, including things like
page refreshes. There is also no ability to determine things like conversion
rates and the like.

Goals:

- Avoid requiring GDPR consent notices.

- The ability to view the number of "unique visitors" rather than just
  "pageviews".

- Basic "bounce rate" and "conversion rate"-like statistics; for example, if
  someone enters on /foo we want to be able to see how many leave after visiting
  just that page, or how many end up on /signup.

Non-goals:

- Track beyond a single browsing session.


Existing solutions
------------------

An overview of existing solutions that I'm aware or with roughly the same goals.

Ackee
-----

https://github.com/electerious/Ackee/blob/master/docs/Anonymization.md

> Uses a one-way salted hash of the IP, User-Agent, and sites.ID. The hash changes
> daily and is never stored.
>
> This way a visitor can be tracked for one day at the most.

This seems like a decent enough approach, and it doesn't require storing any
information in the browser with e.g. a cookie.

It does generate a persistent device-unique identifier though, and I'm not sure
this is enough anonymisation in the context of the GDPR (although it may be?
It's hard to say anything conclusive about this at the moment)

Fathom
------

https://usefathom.com/blog/anonymization

> Unique siteviews are tracked by a hash which includes the site.ID; unique
> pageviews are tracked by as hash which includes the site.ID and path being
> tracked.
>
> To mark previous requests "finished" (not sure what that means) the current
> pageview's hash is removed and moved to the newest pageview.

I'm not entirely sure if it's actually better or more "private" than Ackee's
simpler method. The Fathom docs mention that they "can’t put together an
anonymous, individual user’s browsing habits", but is seeing which path people
take on your website really tracking someone's "browsing habits", or can this
lead to identifying a "natural person"?

Or, to give an analogy: I'm not sure if there's anything wrong with just seeing
where your customers go in your store. The problems start when you start
creating profiles of those people on recurring visits, or when you see where
they go to other stores, too.


SimpleAnalytics
---------------

https://docs.simpleanalytics.com/uniques

> If the Referer header is another.site or missing it's counted as a unique
> visit; if it's mysite.com then it's counted as a recurring visit.

A lot of browsers/people don't send a Referer header (somewhere between ~30% and
~50%); this number is probably higher since Referer is set more often for
requests in the same domain, but probably not 100%.

This is a pretty simple method, but it doesn't allow showing bounce or
conversion rates or other slightly more advanced statistics.


Simple Web Analytics
--------------------

https://simple-web-analytics.com/

Uses the browser cache to achieve season tracking: The endpoint being called by
the tracking code sets the `Expire` header to the next calendar day of the
user's timezone.

This ensures the server only gets hit once per day per session; subsequent
requests are not tracked at all.

In practice there are cases where a session is counted more than once. Firefox
for example ignores the HTTP cache when the user hits the reload button.

It's a simple and un-complex approach, and doesn't require storing any
information about the user (hashed or otherwise) on the server. The downside is
that intermediate requests are not tracked at all, which would make it
unsuitable for GoatCounter.


GoatCounter's solution
----------------------

- Create a server-side hash: hash(site.ID, User-Agent, IP, salt) to identify
  the client without storing any personal information directly.

- Don't persist the hash to disk; this isn't really needed as we just want to
  track the "browsing session" rather than re-identify someone coming back the
  next day.

- The salt is rotated every 4 hour on a sliding schedule; when a new pageview
  comes in we try to find an existing session based on the current and previous
  salt. This ensures there isn't some arbitrary cut-off time when the salt is
  rotated. After 8 hours, the salt is permanently deleted.

- If a user visits the next time, they will have the same hash, but the system
  has forgotten about it by then.

The whole hashing thing is *kind of* superfluous since the data is never stored
to disk with one exception: it's temporarily stored on shutdown, to be read and
deleted on startup. It doesn't hurt to hash the data though, and better safe
than sorry.

I considered generating the ID on the client side as a session cookie or
localStorage,  but this is tricky due to the ePrivacy directive, which requires
that *"users are provided with clear and precise information in accordance with
Directive 95/46/EC about the purposes of cookies"* and should be offered the
*"right to refuse"*, making exceptions only for data that is *"strictly
necessary in order to provide a [..] service explicitly requested by the
subscriber or user"*.

Ironically, using a cookie would not only make things simpler but also *more*
privacy friendly, as there would be no salt stored on the server, and the user
has more control. It is what it is 🤷

I'm not super keen on adding the IP address in the hash, as IP addresses are
quite ephemeral; think about moving from WiFi to 4G for example, or ISPs who
recycle IP addresses a lot. There's no clear alternatives as far as I know
though, but it may be replaced with something else in the future.

Fathom's solution with multiple hashes seems rather complex, without any clear
advantages; using just a single hash like this already won't store more
information than before, and the hash is stored temporarily.
