![Logo](https://raw.githubusercontent.com/Syke94/warframe-info-centre/master/Icons/Warframe.Medium.png) Warframe Info Centre
====================

A Google Chrome extension for keeping up to date on the latest alerts and invasions.

Compatibility
=============

Warframe Info Centre (henceforth referred to as WIC) is only compatible with Google Chrome (version 22 or later required), other Chromium-based browsers have not been tested and WIC will likely not even function with them.

Features
========

* [✔] Automatic updating.
* [✔] Desktop notifications.
* [✔] Alerts support.
* [✔] Invasions support.
* [**x**] Dark Sector support.
* [✔] Fully configurable.
* [✔] User interface.

Building
========

WIC is primarily written in CoffeeScript, which has to be compiled to JavaScript before the extension can be used. If you would like to build this extension for yourself, you will need to perform a few extra steps.

1. Install [Node.js](http://nodejs.org/) if you do not already have it.
2. Install [CoffeeScript](http://coffeescript.org/) with `npm install -g coffee-script`.
3. Install [LESS](http://lesscss.org/) with `npm install -g less`.
4. Navigate to the repository's root directory and run `cake -a build` from the command line to build all **.coffee** and **.less** files.
5. Run `cake export` from the command line to export all necessary files to `Bin` directory.

### Troubleshooting

If you are getting module import errors when trying to `require()` the `coffee-script` and `less` modules, you may not have the `NODE_PATH` environment variable set, or it may be set incorrectly. Ensure that the `NODE_PATH` environment variable exists and points to the directory containing the CoffeeScript and LESS modules.

If importing the modules is not the problem, then there is likely a problem with the build script itself, in which case you should [open a new issue](https://github.com/Syke94/warframe-info-centre/issues). When creating this new issue, please include the text output from the console/terminal as well as the version of WIC you are trying to build (found in the `manifest.json` file on line 8. Ex. `"version": "0.2.3.57"`).

Contributing
============

Want to contribute? Check out the [Contributing](https://github.com/Syke94/warframe-info-centre/wiki/Contributing) page on the wiki for details.

Contributors
============

* [Tony Montana](https://github.com/Syke94) - *Developer, Design*
* [Deathmax](http://deathmax.com/) - *API provider*
* [Kuenaimaku](https://github.com/Kuenaimaku) - *Design*