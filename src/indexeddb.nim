import
  pkg/nodejs/jsindexeddb,
  std/[asyncjs, jsffi, dom]

type
  User* = object
    userId*: cstring
    homeserver*: cstring
    token*: cstring

proc getAll*(indexedDB: IndexedDB; storeName: cstring): Future[JsObject] =
  var promise = newPromise() do (resolve: proc(response: JsObject)):
    let request = indexedDB.open(storeName)
    request.onerror = proc (event: Event) =
      resolve(nil)
    request.onupgradeneeded = proc (event: Event) =
      let database = request.result
      discard database.createObjectStore(storeName, IDBOptions(keyPath: "userId"))
      when not defined(release): echo "upgraded getAll"
    request.onsuccess = proc (event: Event) =
      let
        database = request.result
        transaction = database.transaction(storeName, "readonly")
        obj_store = transaction.objectStore(storeName)
        obj_req = obj_store.getAll()
      obj_req.onerror = proc (event: Event) =
        resolve(nil)
      obj_req.onsuccess = proc (event: Event) =
        resolve(obj_req.result)
  return promise

proc put*(indexedDB: IndexedDB; storeName: cstring; obj: JsObject): Future[bool] =
  var promise = newPromise() do (resolve: proc(response: bool)):
    let request = indexedDB.open(storeName)
    request.onerror = proc (event: Event) =
      resolve(false)
    request.onupgradeneeded = proc (event: Event) =
      let database = request.result
      discard database.createObjectStore(storeName, IDBOptions(keyPath: "userId"))
      when not defined(release): echo "upgraded put"
    request.onsuccess = proc (event: Event) =
      let
        database = request.result
        transaction = database.transaction(storeName, "readwrite")
        obj_store = transaction.objectStore(storeName)
        obj_req = obj_store.put(obj)
      obj_req.onerror = proc (event: Event) =
        resolve(false)
      obj_req.onsuccess = proc (event: Event) =
        resolve(true)
  return promise

proc delete*(indexedDB: IndexedDB; storeName, id: cstring): Future[bool] =
  var promise = newPromise() do (resolve: proc(response: bool)):
    let request = indexedDB.open(storeName)
    request.onerror = proc (event: Event) =
      resolve(false)
    request.onupgradeneeded = proc (event: Event) =
      let database = request.result
      discard database.createObjectStore(storeName, IDBOptions(keyPath: "userId"))
      when not defined(release): echo "upgraded delete"
    request.onsuccess = proc (event: Event) =
      let
        database = request.result
        transaction = database.transaction(storeName, "readwrite")
        obj_store = transaction.objectStore(storeName)
        obj_req = obj_store.delete(id)
      obj_req.onerror = proc (event: Event) =
        resolve(false)
      obj_req.onsuccess = proc (event: Event) =
        resolve(true)
  return promise

proc storeToken*(db: IndexedDB, userId, homeserver, token: string = "") {.async.} =
  discard await indexeddb.put(db, "user".cstring, toJs User(userId: userId.cstring, homeserver: homeserver.cstring, token: token.cstring))
