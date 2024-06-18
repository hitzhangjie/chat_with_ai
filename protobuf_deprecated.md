hitzhangjie:
-------------------------------------------------------------------------------: 
protobuf如何声明一个message定义被废弃了呢？

GitHub Copilot:
-------------------------------------------------------------------------------: 
在 Protocol Buffers 中，你可以使用 `deprecated` 选项来标记一个 message、field、enum、enum value 已经被废弃。这是一个布尔值选项，如果设置为 `true`，则表示该元素已被废弃。

以下是一个示例，展示了如何在 Protocol Buffers 中声明一个 message 已被废弃：

```protobuf
message OldMessage {
  option deprecated = true;

  string old_field = 1;
}
```

在这个例子中，`OldMessage` message 被标记为已废弃。你也可以在 field 级别上使用 `deprecated` 选项：

```protobuf
message SomeMessage {
  string old_field = 1 [deprecated=true];
  string new_field = 2;
}
```

在这个例子中，`old_field` field 被标记为已废弃。

请注意，`deprecated` 选项只是一个标记，它不会改变 Protocol Buffers 的行为。但是，一些 Protobuf 的编译器和 IDE 可能会在你使用被废弃的元素时发出警告。
