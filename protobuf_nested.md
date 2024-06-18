hitzhangjie:
-------------------------------------------------------------------------------
does protobuf message support nested enum, message type?

GitHub Copilot:
-------------------------------------------------------------------------------
Yes, Protocol Buffers (protobuf) does support nested enums and message types. You can define an enum or a message type inside another message type. Here's an example:

In this example, OuterMessage contains a nested message type InnerMessage and a nested enum InnerEnum. The OuterMessage also has fields of these types.