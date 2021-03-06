# rockit
Rock It! is an Android app that helps you stay informed on all things space. It displays upcoming launches and current space news curated by [The Space Devs](https://thespacedevs.com/).

If you just want to try it out quickly, you can open [the web version](https://rockit.010.one/). Please note that it might not work on all browsers (depending on Flutter web support for that browser/version, blocker addons etc.). The experience in the Android app is much better.


### Features
- List upcoming launches and events (e.g. space station activity)
- Show launch/event details and a countdown (including the date and time in your local timezone)
- List latest space news articles
- Subscribe to launches or events to receive notifications before the start or when times are updated
- Search future events and launches
- No internet? No problem! The app caches offline content for a few days and updates it when connected to the internet

### Anti-Features
There's also one [Anti-Feature](https://f-droid.org/docs/Anti-Features/) as defined by F-Droid: this app connects to [Non-Free Network Services](https://f-droid.org/docs/Anti-Features/#NonFreeNet) because it needs to get launch data.

### Credits
All data this app uses is curated by [The Space Devs](https://thespacedevs.com/). This app uses the [Launch Library 2](https://thespacedevs.com/llapi) and [Spaceflight News](https://thespacedevs.com/snapi) APIs.

### Screenshots (dark/light mode)
|                   Launches listing                    |                   Events listing                    |                   Space news                    |
| :---------------------------------------------------: | :-------------------------------------------------: | :---------------------------------------------: |
| ![Launch listing](.github/screenshots/d-launches.jpg) | ![Events listing](.github/screenshots/d-events.jpg) | ![News listing](.github/screenshots/d-news.jpg) |

|                   Launch details                    |                   Event details                   |                   Search launches and events                    |
| :-------------------------------------------------: | :-----------------------------------------------: | :-------------------------------------------------------------: |
| ![Launch details](.github/screenshots/d-launch.jpg) | ![Event details](.github/screenshots/d-event.jpg) | ![Search launches and events](.github/screenshots/d-search.jpg) |

|                   Launches listing                    |                   Events listing                    |                   Space news                    |
| :---------------------------------------------------: | :-------------------------------------------------: | :---------------------------------------------: |
| ![Launch listing](.github/screenshots/l-launches.jpg) | ![Events listing](.github/screenshots/l-events.jpg) | ![News listing](.github/screenshots/l-news.jpg) |

|                   Launch details                    |                   Event details                   |                   Search launches and events                    |
| :-------------------------------------------------: | :-----------------------------------------------: | :-------------------------------------------------------------: |
| ![Launch details](.github/screenshots/l-launch.jpg) | ![Event details](.github/screenshots/l-event.jpg) | ![Search launches and events](.github/screenshots/l-search.jpg) |




### Installation & updates
If you have [F-Droid](https://f-droid.org/) installed, you can add [my repository](https://github.com/xarantolus/fdroid). Make sure you have "Include anti-feature apps" enabled in settings. Then just search for "rockit" in the F-Droid client to download. You will receive update notifications.

Alternatively, you can [download the APK file from the releases section of this repository](https://github.com/xarantolus/rockit/releases/latest). Then open it from the file manager to install it. Please note that you will not receive any update notifications when going this route. You can also watch this repository to get notified for releases.


### [License](LICENSE)
This is free as in freedom software. Do whatever you like with it.
