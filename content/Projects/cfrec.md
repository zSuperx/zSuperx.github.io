---
title: Codeforces Guru
---

[Github Repo](https://github.com/nindroid945/cfrec/tree/main)

[Devpost Submission](https://devpost.com/software/codeforces-guru)

For our submission to HackDavis 2024, my friends and I created an application to
recommend Codeforces problems based on your account’s completed problems.

Because Codeforces has such a rich set of problems, our school’s Competitive
Programming club often likes to use it as the main site to practice on.
Unfortunately, the UI is many years behind its time and doesn’t even offer basic
features like searching for problems based on keywords.

To remedy this, my friends and I created a website & Discord Bot interface to
help you find problems to complete next.

### Features

1. Keyword-based search.
   - Allows for searching problems based on keywords, problem numbers, or ID
2. Recommendation system
   - Granted you've set up the Codeforces API, our system will scan your
     profile's past submissions and suggest problems based on your areas of
     strength and rating of completed problems.
3. Dueling
   - Our Discord Bot offers a command `/duel`, which lets you compete against
     your friends in real time!
   - 5 random problems of increasing difficulty will be selected and shown to
     the players in Discord. (The problems are selected such that neither player
     has completed any of them)
   - The bot will then keep track of each players completions among these 5
     problems to assess their scores!
