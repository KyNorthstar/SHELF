#  SHELF • Simple Heckin’ Entity Library Framework

A simple object-storage solution



## λ☢️ This is in pre-Alpha testing!

This is still in low-level rapid initial development. Expect breaking changes to be frequent, and reliability to be low.

**This is not yet ready for production code!**

Here's the desired features:

- [x] Create
    - [x] Support for JSON-encodable objects
    - [ ] Make it so devs don't have to do `id: .init()` every tim they make their own objects
    - [ ] Support for arbitrary binary blobs, not just JSON
- [x] Read
- [x] Update
    - [ ] Immutable objects maybe?
- [x] Delete
- [ ] Automatically re-load current database
- [x] Concurrency-capable
- [ ] Concurrency-safe
    - [ ] Probably 1 background coordinator task that can spawn as many subtasks as it wants to do the work
- [ ] Relational sugar
    - [ ] Compile-time conveniences (e.g. @Reference resolving to an ID)
    - [ ] A way to delete an object and remove its reference from all other objects, maybe also deleting objects it references
    - [ ] I dunno maybe like a cache of IDs which are commonly associated? That sounds more like a 2.0 kinda thing tho
- [ ] Support for older platforms (currently setting to most-recent for rapid initial development)



## “It's heckin simple!”

The design goal of SHELF is to be as simple to use (or implement yourself!) as possible.

If you want SHELF to store your object, then all you need is to conform its type to `ShelfData`, which only requires that your type is `Codable` and has an `id: ShelfId` field. That's it! From there, you can save & retrieve it to your heart's content


### Example: Saving & retrieving

Given these types:
```swift
import SHELF



struct User: ShelfData {
    let id: ShelfId
    var name: String
}



struct Message: ShelfData {
    let id: ShelfId
    let kind: Kind
    let from: User
    var content: String
    
    
    indirect enum Kind: Codable {
        case plain
        case reply(to: Message)
    }
    
    
    var replyTo: Message? {
        switch kind {
        case .plain: nil
        case .reply(to: let message): message
        }
    }
}
```


You create your objects just like any other:

```swift
let dax = User(id: .init(), name: "Dax")
let eevie = User(id: .init(), name: "Eevie")

let greeting = Message(
    id: .init(),
    kind: .plain,
    from: dax,
    content: "Good morning~"
)

let response = Message(
    id: .init(),
    kind: .reply(to: greeting),
    from: eevie,
    content: "Hay bitch 🧡"
)
```


Storing those objects in SHELF is heckin' simple...

```swift
let shelf = await Shelf()
try await shelf.save(greeting)
try await shelf.save(response)
```


Getting them back out is heckin' simple...

```swift
let retrievedResponse = try await shelf.object(withId: response.id)
assert(retrievedResponse.replyTo == greeting) // True!!
```


Even updating them is heckin' simple!

```swift
try await shelf.update(objectWithId: greeting.id) {
    $0.content.append("!")
}

let retrievedGreeting = try await shelf.object(withId: greeting.id)
assert(retrievedGreeting.content == "Good morning~!") // True!!
```



### SwiftUI App

Here's an entire functioning SwiftUI app which saves & stores the user's name.

```swift
import SwiftUI
import SHELF_SwiftUI



@main
struct App: SwiftUI.App {
    
    @ShelfContext
    private var shelfContext
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.shelfContext, shelfContext)
        }
    }
}



struct ContentView: View {
    
    @ShelfQuery
    private var user: User
    
    @Environment(\.shelfContext)
    private var shelfContext
    
    var body: some View {
        VStack {
            Text("Hello, \(user.name)!")
                .font(.largeTitle)
            
            TextField("Change my name", value: $user.name)
            
            Button("Forget me!") {
                shelfContext.delete(user)
            }
        }
    }
}
```



## Fully Documented!

Documentation is Our special interest ✨



## How are objects stored?

SHELF stores objects in a 2-layer directory hierarchy, using UUIDs as names.

Objects are stored in files whose names are a full standard UUID, which is the ID of the stored object.
The first level of this structure are folders named as the first 2 digits of the object's ID.
Inside those folders are subfolders given the second 2 digits of the object's ID.
Inside those subfolders are the object files themselves.
```
📁 Project Root
└ 📁 .objectStore
  ├ 📄 .shelf-config
  │
  ├ 📁 62
  │ ├ 📁 73
  │ │ ╰ 📄 6273674B-F271-4521-9B74-F5656A1F815D
  │ │
  │ ╰ 📁 AC
  │   ╰ 📄 62AC54A2-8A00-45B0-93B6-3BE499E85219
  │
  ├ 📁 A1
  │ ╰ 📁 FB
  │   ╰ 📄 A1FB9603-3E2A-4915-BD0A-081D0FF7867A
  │
  ├ 📁 A7
  │ └ 📁 F3
  │   ╰ 📄 A7F32199-B32A-49E0-865F-07CE5C5F5F2B
  │
  ╰ 📁 E6
    ├ 📁 51
    │ ╰ 📄 E651E061-7FA2-453D-9FF5-624308BEAE4B
    │
    ╰ 📁 6F
      ├ 📄 E66F1E29-BAE3-4838-A8B1-A8FD3E919033
      ╰ 📄 E66F59A6-EE4E-4F80-96BB-86C162E616F5
```
So objects are stored exactly 2 prefix-folders deep. In the example above, you can see every object exists within folders which make up the first 4 characters of its name, like `Project Root/.objects/A7/F3/A7F32199-B32A-49E0-865F-07CE5C5F5F2B`.

This makes lookup trivial; a simple string-splitting function can build the path, and system calls will tell you whether it exists.

The data inside the object files is formatted as arbitrary JSON.


### `.shelf-config`

The `.shelf-config` file, obviously, stores configuration metadata for this SHELF store.

The version of SHELF used, whether compression was used, etc.



## If you need a custom `FileManager`

Some codebases have specific concerns which require a custom instance or subclass of `FileManager`. If yours is one of those, you're encouraged to create a new `ShelfSerializer` implementation which either contains that custom file manager, or otherwise addresses your needs.

The rest of this SDK should accept that readily without further customization. If you run into trouble, please file a new issue.
