
# Installation Instructions

The recommended way of installing Instacast is through the [App Store](https://itunes.apple.com/app/instacast-core/id1083868334?mt=8).

Alternatively, you can use Xcode to install Instacast on your iOS device using just your Apple ID.

All you need to do is:

1. Install [Xcode](https://developer.apple.com/xcode/download/)
1. Download the [Instacast Source Code](https://github.com/martinhering/instacast) or `git clone git@github.com:martinhering/instacast.git`
1. Open "Instacast.xcodeproj" in Xcode
1. Go to Xcode's Preferences > Accounts and add your Apple ID
1. In Xcode's sidebar select "Instacast" and go to General > Identity. Append a word at the end of the *Bundle Identifier* e.g. com.vemedio.ios.instacast6*.name* so it's unique. Select your Apple ID in Signing > Team
1. Connect your iPad or iPhone using USB and select it in Xcode's Product menu > Destination
1. Press CMD+R or Product > Run to install Instacast
1. If you install using a free (non-developer) account, make sure to rebuild Instacast every 7 days, otherwise it will quit at launch when your certificate expires

[Contact me](https://martinhering.me) if you need help.

## Contribution Guidelines

I am currently only accepting pull requests that fix bugs or add/improve features. I can't allocate time to review pull requests that only refactor things or add comments.