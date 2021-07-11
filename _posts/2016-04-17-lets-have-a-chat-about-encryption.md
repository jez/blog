---
layout: post
title: "Let's Have a Chat about Encryption"
date: 2016-04-17 17:40:17 -0400
description: >
  Discussions of encryption permeate tech and political news sites these days.
  All too frequently though, ideas presented in these discussions draw upon
  outdated analogies and confusion due to technological progression. I think
  it's time to have a chat to answer some questions and move the discussion
  forwards.
comments: false
share: false
redirect_from:
- /2016/04/17/lets-have-a-chat-about-encryption/
---

Discussions of encryption permeate tech and political news sites these days.
All too frequently though, ideas presented in these discussions draw upon
outdated analogies and confusion due to technological progression. I think it's
time to have a chat to answer some questions and move the discussion forwards.

<!-- more -->

A group of friends was walking home from dinner one day. After the usual
discussions of gossip, work, and daily events had worn down, one of them
broached a new topic.

"Have you guys been following the news related to the FBI wanting to force Apple
to weaken the security of its devices?" asked James.

"I think that's Apple's view point," responded Tim.

"Ah, so you have, then! What's your opinion on the matter then?"

This time Emma interjected. "I think the government should stay out of Apple's
business."

And other thought from the group: "I think when it comes to terrorists and other
horrible criminals, Apple should have to unlock their phones if the FBI gets a
warrant, but Apple shouldn't have to make their devices less secure."

"Yes and no," Emma answered. "I believe there are times they should have to hand
over information, but not provide the means to do that to the government."

"That's an interesting thought," said James. "But I think I'm still a little
hazy. Could you give me an example?"

Emma responded, "If the government can prove beyond a reasonable doubt that
someone has committed a crime that threatens people's safety---like what just
happened---then Apple should hand over transcripts and a list of contacts.
However, they shouldn't have to hand over a guide to cracking Apple's security
procedures."

James jumped back in again. "Well, now you two are kind of asking for two
different things.

"The issue now is that those transcripts and lists of contacts might be
encrypted. So are you saying that Apple should hand over the encrypted (meaning:
useless without a key) transcripts and contacts, but that they shouldn't be
forced to withhold using encryption for transcripts and contacts in the first
place?

"The reason why I'm asking is because Apple doesn't have "security procedures"
that can be cracked. It has encryption, and the question is whether people
should be allowed to encrypt things.

"The whole point of encryption is to have security regardless of who you are.
It's founded in math; you can *prove* that a system is secure or insecure. You
can't both be able to unlock a phone at any time while also having a proof that
no one can unlock the phone."

"So what does that really mean? Couldn't Apple just provide the information in
an unencrypted form?" Emma wondered.

"Only if they have the key," said James. "Apple's argument is that they think
holding the keys to someone's encrypted secrets is a power too great for any one
man or organization."

The conversation died down, while everyone contemplated this position. Tim, who
had been walking with his head tilted down facing the sidewalk, slowly looked
up towards a flock of birds flying off in the distance.

"Your right to have your data encrypted and secure goes away when you kill
innocent people," Tim said, sternly.

The group paused once more to consider the implications of Tim's statement. It
James who broke the silence next.

"That's a very rational viewpoint, but in saying that you're also indicting the
same innocent people you claim to defend. Encryption is blind; it it isn't a
privilege given to those worthy of it, nor is it reparations to be paid for a
crime. Encryption is something everyone has access to. Not 'should have access
to' or 'gets to have access to.' It's free and open software.

"You can outlaw the ownership or use of that software, but it's the same thing
as outlawing the ownership of guns; the criminals will use guns or encryption
anyway, and the general populace will not.

Tim was quick to respond this time. "Nothing in life is absolute. Read the
Constitution: it's life, liberty, pursuit of happiness, not subject to
unreasonable search and seizure, etc. No one has an absolute right to
encryption.

"Everyone should have access to encryption, but just like gun ownership, it can
be forfeited, similar to how felons cannot own guns. If a court issues a warrant
that a company help break encrypted data, they should comply."

"What I'm trying to get at is that your viewpoint is contradictory," James
clarified. "Encryption cannot be forfeited after the fact, after it's been
determined that someone shouldn't have access. If something is truly encrypted,
then there is no force other than the key that one person owns that can unlock
that data. I'm not claiming this as an opinion--that's the technical definition
of an encrypted system.

"So if we want companies to be able to comply with 'breaking encrypted data,'
the data itself has to already be broken from the very beginning. It has to be
insecure for everyone for it to be insecure for some one person. Without this,
there's no other way to retroactively 'break encryption' for a single person.

"Now in my opinion, a system that works by being able to be retroactively broken
into is incredibly susceptible to misuse. This misuse could be either by
governments that become tyrannical or by criminals who want to break into a
system for their own gain. I personally feel that we as law-abiding citizens
shouldn't have to give up rights, dropping us down to the same levels as
criminals, before we've even committed a crime."

"And what I'm saying," began Tim, "is this. Everyone is entitled to encrypt
their data. With the proper warrants the government should be able to access
someone's personal data. If that data is encrypted, the government should be
able to task really smart people to figure out the key for that one item. This
should not affect someone else's encryption.

"Now to the point of unbreakable electronic locks," continued Tim. "If these are
truly unbreakable, why aren't they used everywhere and why are hackers able to
break into things?"

James' eyes shone for a moment before he started his response. "That's actually
a really good question. Let me back up a bit to explain.

"A 'hacker' in the traditional sense is actually not too much more than a con
man. The majority of major breaks are what are called 'social engineering
attacks.' Instead of exploiting vulnerabilities in hardware or software, they
exploit vulnerabilities in people. From Wikipedia,

> Social engineering, in the context of information security, refers to
> psychological manipulation of people into performing actions or divulging
> confidential information.

"So most hackers get passwords by tricking other people into divulging them.
Obviously if you have the password, this whole discussion of encryption is moot.
And because it's so easy to get ahold of a password, there is a big push lately
to use what's called 'two factor authentication.' Instead of requiring just a
password to unlock things, you need a password plus some sort of one-time-use
code that is generated securely, usually through an app on your phone.

"The other major types of vulnerabilities access data through poor software
coding practices. There are two common attacks: cross-site scripting attacks
and SQL injection attacks. These attacks target the point of user-input. If not
properly 'sanitized' to remove undesirable inputs, there are some circumstances
where you can for example, enter computer code in a username field, and instead
of just having that input be viewable on the screen, it accidentally gets
treated as code and run on the hosted service. This is known as 'remote
code execution': getting someone else to run code that you wrote. If you can
achieve remote code execution, you can intercept what the software does after it
has unencrypted the data.

"For relatively small applications, the attack vector is small; there are only
so many surfaces in which to enter input, so it's relatively feasible to check
them all diligently. As software systems grow, complexities usually end up
growing quadratically or even exponentially with the number of features added.
It becomes really hard to exhaustively check all attack vectors, and usually
large companies have whole departments devoted to this checking.

"So now that we know how the majority of 'hacking' works, let's talk about
encryption. From Wikipedia:

> Encryption is the process of encoding messages or information in such a way
> that only authorized parties can read it. Encryption does not of itself
> prevent interception, but denies the message content to the interceptor.

"At this point, we can clarify the distinction between the two: 'hacking' is
gaining unauthorized access to a software system, while 'breaking encryption' is
reading a message that you weren't intended to. Hacking deals with privilege
escalation, and encryption deals with privacy.

"There are two types of encryption, but they both share a common goal: taking a
hunk of data and scrambling it in a way that makes it easy to unscramble (given
the password) yet near-impossible otherwise. The two types are called
'encryption at rest' and 'encryption in transit.' Encryption at rest deals with
storing files securely on a hard drive, such that the privacy of those files are
guaranteed even if the drive is stolen. Encryption in transit deals with
communication: making sure that people can't eavesdrop to discover your payment
information, changed passwords, and other communications.

"To put this in context, let's consider a simple messaging application.
Using encryption in transit ensures that the messages sent from one person's
phone to the other can't be eavesdropped, while encryption at rest ensures that
the received messages stored on one person's phone cannot be read unless the
phone is unlocked with a password."

Emma broke the monologue, asking, "So you've mentioned a lot about passwords and
encryption, but here's a simple question: does Apple have the ability to find
out my password? Or if my password is highly secure, does that mean it'll never
be cracked in my lifetime?"

"This brings up an important issue: trust," James responded. "Apple claims
that it uses both of those forms of encryption, but there's no way for you and
me to verify that, other than take their word.

"To answer your question about passwords, the conventional wisdom would say no.
Industry standard practice is to store only a 'hash' of your password, not the
password itself. Every time you log in, the password you type is mangled using
the same method that was used to mangle it when you first enter it, and these
mangled versions are compared. This mangling process is 'one-way': you can't
take the mangled form and go back to the unmangled form, namely your password.

"But do you trust Apple to follow this method? Like we said: there's no way to
know other than their reputation. The only way to truly trust software is to
verify the source code of it, finding out for yourself what it does.
Unfortunately, Apple's code is largely proprietary, so we can't. However, there
are many camps that advocate only using 'open source software': software whose
source can be freely read and inspected. As you might imagine, this type of
software is especially popular with software developers, as it's fun to
inspect the source code of the software you use, with the added benefit that you
can place more trust in it.

"So, does Apple have the ability to find out your password? The answer is most
likely no. They can reset your password if you ask for it to be reset, but this
usually involves verifying your identity through your email provider.

"And regarding your second question, about whether your password can be cracked,
you're exactly right. A secure password can't be cracked in any reasonable
amount of time.

"There are a number of ways to attack password-based systems, the most common
(other than social engineering attacks) being a 'dictionary attack.' This
involves going through entire dictionaries, trying words, phrases, words with
numbers in various places, and words with weird capitalization. So if you have a
short, simple password, you're likely vulnerable to a dictionary attack. Even if
you have a short, complicated password, dictionary attacks tend to be fairly
successful. That's why it's best to have long passwords, because as the
dictionary crackers run out of words, it degenerates into a case of trying all
possible strings. For example, if your password is 16 characters long, they'd
have to try all 26^16 possible inputs---we're talking many, many guesses here.

"And when we typically talk about 'encrypted' data, we're talking about data
that has been locked up with a key that's 128 characters long: 26^128
possibilities! To put that in context, our best guess for the number of atoms in
the universe is close to 10^80. 26^128 is an absolutely huge number.

"Since you sound curious, the math that protects these encryption schemes is a
problem called 'prime factorization.' Basically, if you take two really big
prime numbers *p* and *q* and multiply them, the number you get is *pq*, and
only has two factors: *p* and *q*. If you know *pq* and want to get *q*, you
'divide' by the key *p*. Division on modern computers is super fast, so
decrypting some data with the correct password is too. However, if you chose a
large, random key *p* in the first place, it will take a really long time to
guess what the key actually was before you can do the division.

"That's a lot of information. With respect to the situation with Apple, all
iPhone hard drives are encrypted at rest, meaning their data cannot be decoded
without the lock password. The FBI wanted a way to circumvent this, by being
able to try brute-forcing lock passwords without the phone self-destructing.
In order to do this, Apple would have had to write code that allowed that to
happen. Apple's argument was that this act of writing code amounted to compelled
speech, which is protected by the Constitution, and which has legal precedent
when applied to code.

"After the case between FBI and Apple, it prompted many discussions about
whether encryption itself should be legal. In particular, there is a draft of a
bill in the Senate Intelligence Committee that is particularly foreboding for
the legal use of encryption. That's why I broached the subject in the first
place, as I saw this in the news the other day. It's pretty concerning that
people want to see encryption weakened so that law-abiding citizens cannot have
privacy for the sake of denying criminals their privacy."

The group had finally arrived back home at their building. They passed inside
and headed back upstairs. "No kidding that was a lot of information," said Emma.
"And I can definitely see where you're coming from; it scares me a bit too when
you put it that way. I'm glad you brought it up though. I feel like I have a
grasp on things now that I didn't before. Thanks."


<!-- vim:ft=pandoc.liquid
-->
