# simple-matrix-client

A simple matrix web client implemented using [matrix-nim-sdk](https://github.com/dylhack/matrix-nim-sdk/).

![image](docs/client.png)

Features:
 - Stores previously signed-in accounts in IndexedDB
 - Guest registration

TODO:
  - [ ] Get chat name for chat list
  - [ ] Store in IndexedDB:
    - [x] login token
    - [ ] sync data
    - [ ] room states
  - [ ] Make it faster on large accounts
