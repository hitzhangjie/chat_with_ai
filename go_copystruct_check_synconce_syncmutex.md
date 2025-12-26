## TL;DR

- **Embed `sync.Once` by value** – it’s a small struct whose zero value is already ready to use.
- **Don’t use `*sync.Once` unless you really need to share the same `Once` across multiple structs** (or you want to avoid copying the whole struct, but that’s rarely the 
case).
- **Never copy a struct that has already called `Do` on its `sync.Once`** – a `sync.Once` is *not* safe to copy after it has been used.

---

## Why `sync.Once` is usually a value field

```go
type MyService struct {
    once sync.Once
    // other fields …
}
```

* `sync.Once` is just a tiny struct (currently one pointer to an internal state).  
  Copying it is cheap.
* The zero value of `sync.Once` is already a functional “once” object, so you don’t need to allocate or initialize it.
* Embedding it (or having it as a named field) gives you the idiomatic `foo.once.Do(...)` pattern.
* Most examples in the Go standard library and in real code use it by value.

---

## When you might consider a pointer

| Scenario | Why a pointer might help | What you trade off |
|----------|------------------------|-------------------|
| **You want to share the same `Once` between many structs** | All structs would call the *same* once instance, so the initialization runs only once across all of them. | You 
lose the automatic promotion of `Do` and you need to manage the pointer’s lifecycle. |
| **You want to avoid copying a struct that contains a `sync.Once`** | If you copy the struct after `Do` has been called, the copy may run the init again or cause a race. A 
pointer to the whole struct (or a separate pointer to the `Once`) keeps a single `Once` instance that is not duplicated. | You still have to be careful not to copy the struct 
itself; a pointer to the `Once` doesn’t magically make the struct copy‑safe. |
| **You need to defer the creation of the `Once` until runtime** | `*sync.Once` lets you set it to `nil` until you need it. | `sync.Once` is already zero‑valued and ready; you 
rarely need this. |

In almost every typical use‑case you’ll see `sync.Once` embedded as a value.

---

## The “copy‑after‑Do” gotcha

```go
type Cache struct {
    once sync.Once
    data map[string]int
}

func (c *Cache) Init() {
    c.once.Do(func() {
        c.data = make(map[string]int)
    })
}

func main() {
    var c1 Cache
    c1.Init()

    // BAD: copying a struct that already used its Once
    c2 := c1 // copies the Once!
    c2.Init() // could run the init again – undefined behavior
}
```

`sync.Once` contains a state flag that is **not** safe to copy after the first `Do`.  
If you need a struct that can be copied, keep a pointer to the whole struct or ensure you never copy it after the `Once` has run.

---

## Bottom line

- **Use `sync.Once` as a value field** inside your struct.  
- **Avoid `*sync.Once` unless you have a very specific need** to share the same instance or to avoid accidental copies.  
- **Never copy a struct that has already used its `sync.Once`**. If you need a copy‑able type, copy the pointer to the struct instead.

That’s the idiomatic and safest pattern in Go.
