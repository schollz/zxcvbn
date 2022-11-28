---
title: Abstract
weight: 1.0
---


<img src="/static/main1.png" class="fr">

*zxcvbn* is a [tracker](https://en.wikipedia.org/wiki/Music_tracker) for [norns](https://monome.org). *zxcvbn* is best used with a keyboard. The keyboard is used to create musical expressions in the [tli syntax](#tli) for sequences on up to ten different tracks that can control [eleven different clades](#clades). Clades are sound systems which include multiple samplers, and over a dozen internal synth engines.



## Install

Installation is a multi-step progress. Make sure you have an internet connection, at least 150 MB of free space, and at least 10 minutes.

1. Download *zxcvbn* from the maiden catalog, or enter the install command into the maiden repl:

`;install https://github.com/schollz/zxcvbn`

After installing, you will need to restart your norns. 

2. Start *zxvcbn*. You will see `loading...` and it might take a few minutes. Just wait. After it finishes, restart the norns.

3. Start *zxcvbn* again. This time it'll say to "Press K3 to install". When you have a stable internet connection, you can press *K3* and wait. Installation may take up to 10 minutes.

4. Play! After step 3, *zxcvbn* will automatically load with a demo program. Use *ctrl* + *p* to play a track and *ctrl* + *0-9* to select a track. The first time you start you will see a demo song (which you can load back up through the `PSET` menu). Read further to learn other invocations.


## Bugs

Its inevitable that you may experience bugs. Please report bugs back to me through the [lines forum](https://llllllll.co/t/zxcvbn) or through [github](https://github.com/schollz/zxcvbn/issues/new?assignees=&labels=&template=bug_report.md&title=).

When sharing a bug, its vital to include the system log and a specification of what kind of norns you are using (physical device, shield, fates, desktop, etc). Follow [these instructions for gathering system logs](https://monome.org/docs/norns/help/#logs).

## Contributions

I am wholly open to any and all contributions. The repository is entirely open-source on [Github](https://github.com/schollz/zxcvbn). No special rules, make a PR for something you need and I will accept it. Don't hesitate to get in touch if you need help getting an idea off the ground.

If you'd like to edit this document as well, there is a "<i class="fas fa-edit" aria-hidden="true"></i>" you can click around this document to edit pieces.


## Acknowledgements


*zxcvbn* is heavily inspired by its predecessor, [yggdrasil](https://northern-information.github.io/yggdrasil-docs/).  The inner workings also combine together several previously written scripts - [amen](https://github.com/schollz/amen), [internorns](https://github.com/schollz/internorns), [tmi](https://github.com/schollz/tmi) (now revisioned as "tli"), [paracosms](https://github.com/schollz/paracosms), [mx.samples](https://github.com/schollz/mx-samples), and [mx.synths](https://github.com/schollz/mx-synths).


Many of the pieces in this script wouldn't be possible without help from others who I am infinitely grateful. The initial ideas for this script were formulated two years ago by the Northern Information personnel ([@tyleretters](https://stuxnet.me/), and [@license](https://github.com/ryanlaws)).  The `mx.samples` clade was helped by the digital ghost [@zebra](http://catfact.net/) (in fact a great deal of every facet of the norns system is due to their ingenuity along with [@dndrks](https://github.com/dndrks) and [@tehn](https://nnnnnnnn.co/)). The `mx.synths` clade has contributions from [@alanza](https://alanza.bandcamp.com), [@timriot](https://github.com/timriot),  [@sixolet](https://github.com/sixolet) and [@chrislo](https://github.com/chrislo). The `drum` clade and the `infinite pad` started off as an exercise in understanding [@nathan](https://nathan.ho.name/)'s [SuperCollider videos](https://www.youtube.com/channel/UCOLGEEl-F3vQ6M1chJ5DsEw). The reverb comes from [@jpcima](https://github.com/jpcima/fverb). The whole thing is based off the wonderful tool from  [@monome](https://monome.org). Suffice to say - I've had a lot of inspiration from the norns community that helped me grow as a musician and coder from all those previously mentioned that contributed pieces to this project and also many, many others.