# simple-matrix-client

A simple matrix web client implemented using [matrix-nim-sdk](https://github.com/dylhack/matrix-nim-sdk/).

![image](docs/client.png)

Features:
 - Stores previously signed-in accounts in IndexedDB
 - Guest registration with display name

TODO:
 - [x] Indicate what chat is currently selected
 - [x] Send messages
 - [x] Store login token in IndexedDB
 - [x] Display encrypted messages
 - [x] Long-polling for Sync API
 - [ ] Refactor and setup a proper data store for sync and chat data
    - [ ] use global vars to store data from initial sync
    - [ ] subsequent syncs / get messages will add to those vars
 - [ ] Infinite scroll for messages
 - [ ] Get chat name for chat list
 - [ ] Properly name DMs in chat information pane
 - [ ] Make it faster on large accounts
 - [ ] Make the UI more mobile friendly
 - [ ] Add logout button
 - [ ] Add exit button for messages and chat info panes