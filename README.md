![BA Suite Showcase GIF](preview.gif)

<sub>Sources for the wallpaper are listed [at the end of the README](https://github.com/Xenon257R/blue-archive-rainmeter#showcase-wallpaper-sources).</sub>

# Blue Archive - Rainmeter Suite
A full *Blue Archive* themed *Rainmeter* suite for your desktop. Does not come with wallpapers. This suite was built with ***form over function*** in mind and as such may fall behind more traditional, streamlined *Rainmeter* skins in terms of easily customizable features.

Before use, it is advised to carefully read through every skin's **Information** tag and understand the features of each one to see which skins and variants are best suited for you.

## Feature List
- Primary Banner displaying user level (decorative)
  - Variant: Weather display (uses [Weather.com](https://weather.com)'s API)
- Battery life display
  - Variant: Login duration display (partially decorative)
- Free storage space counter
- Network In/Out speed display
  - Daily pseudo-random premium currency generator (decorative)
- General Options tray
  - Includes *Resource Monitor*, *Rainmeter* and *Style Settings* as defaults
- Master **Refresh** button
- Master **ToggleSwitch** button
  - Requires child button **ToggleOn** (on by default) to function properly
- Desktop "Sticky" Notes
- Audio visualizer (can be toggled)
- Social App of choice shortcut
- Recycle Bin shortcut
- Mini Audio Player (collapsible)
- **File Explorer** shortcut
  - Variant: Manga tracker (uses the [Mangadex API](https://api.mangadex.org/docs/)) - still doubles as a **File Explorer** shortcut
- *Steam News* marquee (uses the [Steam News Hub RSS Feed](https://store.steampowered.com/feeds/news/))
- *YouTube* channel uploads marquee (uses the YouTube RSS Feed)
- Large taskbar tray
  - Includes a *SCHALE* icon that can be used as a template
    - also has simplified version
  - Displays Date & Time
  - Includes Master Audio App (of those supported by _Rainmeter_)

The suite also comes with a small set of default icons for common *Windows* directories, popular web browsers, several _Rainmeter_ supported music players and halos of various *Blue Archive* characters.

## Installation and Setting Up
This suite has been tested for Windows 10 and *Rainmeter* version **4.5.17** and above.

As this is not your typical modular skin and instead a fully fleshed-out suite, it will require a little bit of patience to set up.
1. You will first need the latest version of *Rainmeter* which you can get on [their official website](https://www.rainmeter.net/)
2. Download the latest version of the suite in the [Releases page here](https://github.com/Xenon257R/blue-archive-rainmeter/releases)
3. Install the skin by double clicking the `.rmskin` file
4. At this point, you can refer to one of two (or both!) webpages to complete your setup:
   - The [Beginner's Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=2864554818) on *Steam Guides*, serving as a tutorial to those who may be unfamiliar or inexperienced with *Rainmeter*
     - Will go partially in-depth about the optional *Wallpaper Engine* component as well
   - The [GitHub Wiki](https://github.com/Xenon257R/blue-archive-rainmeter/wiki) (currently under construction!), serving as a manual that goes in-depth for individual skins
5. And you're done!


## Customization
This suite comes with built-in UIs to simplify the process of personalizing the *Rainmeter* setup beyond the loaded default. This includes visual settings, database settings, global scaling, and more! Refer to the documentation on either of the webpages mentioned above to see how each skin can be customized, or you can poke around buttons and context menus and find out from your own curiosity.

## Custom App Icons
[This GoogleDrive](https://drive.google.com/drive/folders/1OVEtbCvVYwbtnVyXGevAI2oaCRHt1O_t) currently contains all custom/specialty apps that didn't have a reason to be in the installation package. I will slowly update the drive with more apps over time when I have some spare time and will remain outside of this GitHub repository so that the suite doesn't become bloated with just icon updates and the repository is free from the risk of getting too large that it hits the storage limit.

I've written a spritesheet breakdown for the complex app icons that this suite utilizes in both the Steam Guide and the Wiki in their respective TrayApps sections, and hopefully it explains things well enough that you can draw up your own!

## Additional Notes
The preset that comes with the `.rmskin` package will assume you have a 16:9 resolution and scale to your active window's height. This does not mean it will not work otherwise; it will still make its best attempt for the initial setup and in theory should only fail spectacularly if you have a narrow screen. It is up to you to adjust the position and size of skins to your specifications.

To reduce network consumption, every skin that connects to the internet to download information will only do it once in bulk during Rainmeter's startup and when at least an hour as elapsed since the last check. As such, displayed information such as a *YouTube* channel's latest upload should not be treated as live feed.
- The one exception to this rule is the **Primary Banner**, which updates on its own once every hour (minute if the variant is the **User Level**).

This suite does **NOT** intend to serve as a full replacement of various services such as the [Steam News Hub](https://store.steampowered.com/news/) as it does not aim to replicate their full feature list - it is just miniature widget for tracking updates. Treat skins like YouTubeBubble as a fancy, themed bookmark and nothing more.

## Credits

- [Weather.com V3 JSON](https://forum.rainmeter.net/viewtopic.php?f=118&t=34628#p171501) - JSMorley
- [ConfigActive Plugin](https://github.com/jsmorley/ConfigActive) - JSMorley
- [CursorColor Plugin](https://github.com/jsmorley/PluginColorCursor) - JSMorley

**Disclaimer:** This suite is a fan-made project inspired by *Blue Archive* and not directly affiliated with it. Copyright remains with the developer and publisher of *Blue Archive*: Nexon, NAT GAMES and Yostar.

### Showcase Wallpaper Sources
- [Blue Archive Konuri Maki - Fully Interactive L2D](https://steamcommunity.com/sharedfiles/filedetails/?id=2945479388) by Xenon257R (privated - will be available at a later notice)
- [Pokémon HM03 (Surf)](https://steamcommunity.com/sharedfiles/filedetails/?id=2869069229) by ITZAH
- [도기코기 DoggieCorgi](https://steamcommunity.com/sharedfiles/filedetails/?id=1661383396) by (Han)dals and stgoindol
- [Bell Tower / Pokemon Heartgold](https://steamcommunity.com/sharedfiles/filedetails/?id=2292763401) by JD
- [Evangelion Beserk Mode](https://steamcommunity.com/sharedfiles/filedetails/?id=1626467688) by T1T0
- [*Bliss*](https://en.wikipedia.org/wiki/Bliss_(image)), photograph by Charles O'Rear
