# act13inclass

A new Flutter project.

## Getting Started

Activity 13: Firebase authentication

Using a flutter app that uses firebase email and password authentication which
users can register sign in and view their profile and sign out 

Features 

- Registration and sign wiith firebase aithentication

- Authentication routing where signed out users and see the authentications creen and signed in users see the profile 

- Profile displays the email form the authenticated firebase user 

- Password updates with the current passowrd , email format valication and 6 word password baseline

- Light blue theme with white input fielkds

Main dart is where the firebase initializes and defines the theme and uses authfate to choose the screen 

The authservice dart has the authservice and authscreen as seperate classes. The firebase account operations stay in the service from the display and feedback stays in the widget 

profilescreen dart displays the signed in email and provides the passowrd update and sign out actions. 

firebaseoption dart is the platform config created by flutterfire. 
