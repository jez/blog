---
layout: post
title: "Update Your Software: It's the Law"
date: 2014-06-11 22:22:57 -0400
comments: true
categories: [terminal, unix, best practices]
description: I wrote a short bash snippet to check my command line software for updates and alert me once a day.
image:
  feature: /images/abstract-6.jpg
  credit: dargadgetz
  creditlink: http://www.dargadgetz.com/ios-7-abstract-wallpaper-pack-for-iphone-5-and-ipod-touch-retina/
share: true
---

Okay, so maybe the government won't come after you for not updating. But they should. To guard off any present or future threats (be they from governments, security vulnerabilities, or something else in the cyber realm), I wrote a short bash snippet to check my system for outdated packages.

<!-- more -->

## Obligatory Existential/Meta Section
I don't quite know what prompted me to suddenly become interested in maintaining an up to date system. Maybe it was [this post][arch-discussion] of Arch Linux horror stories. Maybe it was the release of [git 2.0][git], which introduces a lot of cool new features and deprecates a lot of others. Who knows, maybe it was influenced by Heartbleed and the [host][openssl] [of other][feedly] [high-profile][evernote] security vulnerabilities and hacks that have sprung up lately. It's probably a combination of all of these. Let's move on.

For the impatient among us, here's the code, which is also available [here][snippet1] and [here][snippet2] amongst all the code for [all my dotfiles][dotfiles].

{% codeblock lang:bash Alert to Update https://github.com/jez/dotfiles/blob/master/bash_profile#L16-L42 %}
# ----- daily updates --------------------------------------------------------
[ ! -e $HOME/.last_update ] && touch $HOME/.last_update
# Initialize for when we have no GNU date available
last_check=0
time_now=0

# Unix last command to check the log of logins, grab the most recent
last_check_string=`ls -l $HOME/.last_update | awk '{print $6" "$7" "$8}'`

# Darwin uses BSD, check for gdate, else use date
if [[ `uname` = "Darwin" && -n `which gdate` ]]; then
  last_login=`gdate -d"$last_check_string" +%s`
  time_now=`gdate +%s`
else
  # Ensure this is GNU grep
  if [ -n "`date --version 2> /dev/null | grep GNU`" ]; then
    last_login=`date -d"$last_login_string" +%s`
    time_now=`date +%s`
  fi
fi

time_since_check=$((time_now - last_login))

if [ "$time_since_check" -ge 86400 ]; then
  echo "$cred==>$cwhiteb Your system is out of date!$cnone"
  echo 'Run `update` to bring it up to date.'
fi
{% endcodeblock %}

{% codeblock lang:bash Check for Updates https://github.com/jez/dotfiles/blob/master/bash_profile#L153-L178 %}
# ----- function -------------------------------------------------------------
update() {
  touch $HOME/.last_update

  # Mac updates
  case $HOSTNAME in
    *Jacobs-MacBook-Air*)
      echo "$cblueb==>$cwhiteb Updating Homebrew...$cnone"
      brew update

      echo "$cblueb==>$cwhiteb Checking for outdated brew packages...$cnone"
      brew outdated --verbose

      echo "$cblueb==>$cwhiteb Checking for outdated rbenv...$cnone"
      cd $HOME/.rbenv
      git fetch
      if [ "`git describe --tags master`" != "`git describe --tags origin/master`" ]; then
        echo "rbenv (`git describe --tags master`) is outdated (`git describe --tags origin/master`)."
        echo "To update, run: cd ~/.rbenv; git merge origin master && cd -"
      fi
      cd - 2>&1 > /dev/null

      echo "$cblueb==>$cwhiteb Checking for outdated ruby gems...$cnone"
      gem outdated
      ;;
  esac
}
{% endcodeblock %}

You'll note the use of a touch file (created in line 2 of the first snippet if it doesn't already exist). If this file is 24 hours old, each time this code is run an alert will be printed. Since this code is running inside of my `.bash_profile`, that means that every time I open a terminal on a 24-hour-old system, I see the update message.

Next, you'll note that I've defined a function called `update` which is actually misnamed. This function merely checks for available updates instead of actually performing the updates, logging those packages, gems, and formulae it finds that are out of date. For my purposes, I only need to update brew, check for formulae updates, update rbenv, and check for gem updates. Obviously though, given that there is a way to programmatically check something for updates, plugging that code in here would check it as well. This means that this method is very easy to customize and extend for various needs.

## Rant
I was planning on checking pip for updates as well, but pip is kind of not even good. To give you an idea, to check all the packages brew manages for updates, you type `brew outdated`, and it will list the formula name, current version number, and newest version number. Meanwhile, back in the land of pip, no such functionality exists (at least, simple functionality, and functionality that I could find. If you'd like to correct me, be my guest!). I'm sure that this script will grow as I come to manage more and more pieces of software on my system and others.

If you have any questions about what I've done here, or you catch some bugs, be sure to comment below or file an issue on GitHub! I'd love to hear what you have to say.

{% include jake-on-the-web.markdown %}

[arch-discussion]: https://www.facebook.com/groups/cmuscs/permalink/727878180603546/
[git]: https://git.kernel.org/cgit/git/git.git/tree/Documentation/RelNotes/2.0.0.txt
[openssl]: https://www.openssl.org/news/secadv_20140605.txt
[feedly]: http://grahamcluley.com/2014/06/feedly-blackmail-ddos/
[evernote]: http://blog.evernote.com/blog/2013/03/02/security-notice-service-wide-password-reset/
[snippet1]: https://github.com/jez/dotfiles/blob/master/bash_profile#L16-L42
[snippet2]: https://github.com/jez/dotfiles/blob/master/bash_profile#L153-L178
[dotfiles]: https://github.com/jez/dotfiles

