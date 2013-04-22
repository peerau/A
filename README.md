A
=

A - An Admin service for extending an SRA's powers on Charybdis networks.

Written for Ruby 2.0. Lower versions *may* work, but are unsupported.

Requires socket and monitor (both standard libraries), optionally
openssl.

License
-------

MIT license, see LICENSE.

Installation
------------

Installation is simple, as this is not a gem. Simply copy
etc/A.conf.example to etc/A.conf and change the configuration file. You
are permitted to feel a strong sense of nostalgia while doing so.

Then run bin/run.rb.

Future
------

A is generally considered "working" and we're lazy people. Pull requests
are wecome and likely to be accepted if they appear to work.

There are plans to implement an InspIRCd protocol, but due to different
extban mechanics, this won't happen unless a core dev really needs A on
an InspIRCd network. A patch to implement this is going to be accepted,
though.

