# simple-matrix-client [![Web deployment](https://github.com/tandy-1000/simple-matrix-client/actions/workflows/web.yml/badge.svg)](https://github.com/tandy-1000/simple-matrix-client/actions/workflows/web.yml)

A simple matrix web client implemented using [matrix-nim-sdk](https://github.com/dylhack/matrix-nim-sdk/).

![image](docs/client.png)

## Features:
 - Stores previously signed-in accounts in IndexedDB
 - Guest registration with display name

## How to run as a web app

Requirements:
 - Dart Sass

Run the following commands:
```
cd simple-matrix-client
nimble sass
nimble buildjs
nim r simple_matrix_client/server.nim
```

## How to use as a library

```
cd simple-matrix-client
nimble install
```

To embed a full client on a page, you can use `matrixClient(): Vnode`.

To package the client's CSS, build `library.sass` located in the packages nimble folder:

`~/.nimble/pkgs/simple_matrix_client-0.1.0/simple_matrix_client/sass/library.sass`

### TODO:
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
