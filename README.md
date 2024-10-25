# cdnprobe

v1.0

Quick shell script to probe IPs of the main global CDN providers for a specific website.

## Usage

```
$ ./cdnprobe.sh domain [path] [schema]
```

## Technique

`cdnips.json` contains a sample of IPs from each CDN provider. It was constructed by taking the minimum set of IPs that "seems to cover" most websites of a CDN (for those websites that are published in non-dedicated IPs). This means that, by probing each of these IPs with GET requests setting a custom SNI and Host header with the requested site, we should be able to find a site quickly in the top CDNs, if it exists there in "shared IP space". 

In the "ideal scenario", all edge servers of a CDN provider would respond to all sites published in the CDN, but this is not always the case. In some cases, edge servers are only responsible for a subset of sites hosted in the provider. To mitigate this issue and increase effectiveness, this list should be maintained by following these rules:

* In case a provider seems to behave ideally, still choose 3 valid IPs to probe to keep the tool working for an extended period of time;

* In case a provider does not behave ideally, find a sample of all IPs of a CDN (it's usually provided publicly or can be found via OSINT) and probe them for a set of reasonably "distant" sites (different companies from different countries, etc) that are known to exist in that CDN. Check which IPs responded with the real content from each requested site. If the list is exhaustive, include in the list a single IP that responded for each requested site, or a small number of them. If not, include all IPs that responded with the real content.

This idea is not static and works best if adapted for each provider, once we have some basic knowledge about how it works under the hood. The goal must always be to increase the effectiveness of the analysis without having to perform thousands of requests.

* Validation is run by maintaining a ground-truth list of websites of companies that exist in a set of CDNs and verifying if the probes behave as expected over time;

## Key Questions

### Why is this relevant?

Nowadays many companies like the cloud. They use the cloud for everything - CDN, WAF, managed apps and databases, etc. Enumerating cloud infrastructure as a whole is very time consuming, as it usually requires one to send hundreds of thousands (sometimes, millions) of packets. But some companies use more than one provider for different needs, and some *change* their providers relatively often. This leads to messes that can be exploited. Here are some scenarios where this sort of analysis might be useful:

* When a site uses provider A for their WAF and provider B for their CDN (A > B), but does not properly restrict requests reaching B to the IPs of A, knowing B it may be feasible to reach it directly, bypassing WAF protections.

* When a site uses provider A for their CDN but used provider B in the past and didn't clean up properly, knowing B it may be feasible to reach it directly, sometimes bypassing protections that may be in place in A.

* The same may happen in the weird scenario where a site uses two CDNs, one pointing to the other, where the second doesn't have the same protections as the first.

### What is the SNI and why is it important?

The SNI (Subject Name Indication) is a field provided as an extension of the Client Hello in the TLS handshake. It's a plaintext field that contains the domain name of the site being requested, for the purposes of informing the server the subject of the certificate that is to be used to secure the connection. This is important because the same server may "host" a number of different sites. The other field that informs the server of the site being requested, the Host header of the HTTP request, is sent after the TLS handshake, and thus encrypted. To avoid this "chicken-and-egg" problem we use the SNI - otherwise, the TLS certificate provided by a server would have to specify the subject of all sites hosted in it, which would be hard to manage, or a wildcard, which is not always desired.

To illustrate this, if you type "https://<somedomain>" in your browser or send a basic HTTPS request with curl, both the SNI and the Host header are sent as `somedomain`. The server will respond with a certificate for the proper domain, complete the handshake, and then return the contents for the site requested in the Host header.

If you change the Host header naively with `curl -H 'Host: X' 'https://IP'` or, let's say, using a custom browser extension, the SNI will be the IP, while the Host header will be X. The problem is that some servers won't even complete the TLS handshake if the provided SNI doesn't exist in their server or may behave in strange ways if the SNI differs from the Host header (which corresponds to another evasion technique known as Domain Fronting). To sync the SNI and the Host header we must have either static DNS entries, a custom DNS resolver, or a flexible tool. An alternative using `curl`, for example, is to use its' `--resolve` argument to specify a static DNS entry to be used in the connection. Other hacks can be performed, such as using sandboxing (like [bubblewrap](https://github.com/containers/bubblewrap)) to run specific programs with different `/etc/resolv.conf` or `/etc/hosts` configurations. But we don't need all that, since `httpx` has a `-sni` flag that can be used along with `-H` and is already a great tool for probing experiments due to its' diversity of features. 

## Dependencies

* [httpx](https://github.com/projectdiscovery/httpx)
* [jq](https://github.com/jqlang/jq)

## License

MIT License

Copyright (c) 2024 Artur Marzano

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
