---
title: Abstract
weight: 1.0
---


<img src="/static/main1.png" class="fr">

*zxcvbn* is a [tracker](https://en.wikipedia.org/wiki/Music_tracker) for [norns](https://monome.org). *zxcvbn* is best used with a keyboard. The keyboard is used to create musical expressions in the [tli syntax](#tli) for sequences on up to ten different tracks that can control [eight different clades](#clades) ("clades" are sound systems).


## Inspiration

*zxcvbn* is heavily inspired by its predecessor, [yggdrasil](https://northern-information.github.io/yggdrasil-docs/), as well as [beacon](https://norns.community/en/authors/tomw/beacon), [internorns](https://norns.community/en/authors/infinitedigits/internorns),  and [crow_talk](https://norns.community/en/authors/justmat/crow_talk). 

The inner workings also combine together several previously written scripts - [amen](https://norns.community/en/authors/infinitedigits/amen), [tmi](https://norns.community/en/authors/infinitedigits/tmi) (now revisioned as "tli"), [paracosms](https://norns.community/en/authors/infinitedigits/paracosms), [mx.samples](https://norns.community/en/authors/infinitedigits/mx-samples), and [mx.synths](https://norns.community/en/authors/infinitedigits/mx-synths).


## Install

Install from the maiden catalog, or enter the install command into the maiden repl:

`;install https://github.com/schollz/zxcvbn`

After installing, you will need to restart your norns.

Then start the script and you'll be asked to install required libraries. These take up about 150 MB of disk space. Press K3 to accept and install - installation may take up to 5 minutes.


## Bugs

Its inevitable that you may experience bugs. Please report bugs back to me through the [lines forum](https://llllllll.co/t/zxcvbn) or through [github](https://github.com/schollz/zxcvbn/issues/new?assignees=&labels=&template=bug_report.md&title=).

When sharing a bug, its vital to include the system log. I can use this log to figure out exactly what happened, but without it it will be difficult to determine. Follow [these instructions for gathering system logs](https://monome.org/docs/norns/help/#logs).

## Acknowledgements

This system is built from many pieces which have been forged over the past two years by many hands. The initial ideas were formulated by the Northern Information personnel ([@tyleretters](https://stuxnet.me/), and @license). The `mx.samples` clade involves a lot of help from the digital ghost @zebra (in fact a great deal of every facet of the norns system is due to their ingenuity). The `mx.synths` clade has contributions from @alanza, @timriot,  @sixolet and @chrislo. The `drum` clade and the `infinite pad` started off as an exercise in understanding Nathan Ho's [SuperCollider videos](https://www.youtube.com/channel/UCOLGEEl-F3vQ6M1chJ5DsEw). The reverb comes from [@jpcima](https://github.com/jpcima). Just generally there was a lot of inspiration from the norns community that helped me grow as a musician and coder - namely thanks to all those previously mentioned and also @dndrks, @jaseknigter. Also thanks to @monome for creating such a cool tool to begin with.
