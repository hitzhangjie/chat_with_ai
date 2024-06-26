# Events Specification

## Problem

Events are everywhere. However, event producers tend to describe events differently.

The lack of a common way of describing events means developers are constantly re-learning how to consume events. This also limits the potential for libraries, tooling and infrastructure to aid the delivery of event data across environments, like SDKs, event routers or tracing systems. The portability and productivity that can be achieved from event data is hindered overall.

## CloudEvents

CloudEvents is a specification for describing event data in common formats to provide interoperability across services, platforms and systems.

Event Formats specify how to serialize a CloudEvent with certain encoding formats. Compliant CloudEvents implementations that support those encodings MUST adhere to the encoding rules specified in the respective event format. All implementations MUST support the [JSON format](https://github.com/cloudevents/spec/blob/main/cloudevents/formats/json-format.md).

For more information on the history, development and design rationale behind the specification, see the [CloudEvents Primer](https://github.com/cloudevents/spec/blob/main/cloudevents/primer.md) document.

## Specification

Please read:

- https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md

Following is an event example which is serialized as JSON:

```json
{
    "specversion" : "1.0",
    "type" : "com.github.pull_request.opened",
    "source" : "https://github.com/cloudevents/spec/pull",
    "subject" : "123",
    "id" : "A234-1234-1234",
    "time" : "2018-04-05T17:31:00Z",
    "comexampleextension1" : "value",
    "comexampleothervalue" : 5,
    "datacontenttype" : "text/xml",
    "data" : "<much wow=\"xml\"/>"
}
```

Some properties meanings:

- specversion, the specification version which this event conforms to
- source, where the event happens
- id, the unique id which is guaranteed by the producer
- time, the time when the event happens
- data, the event payload
- datacontenttype, the event payload encoding format
- etc.

## Products

EventMesh, https://github.com/apache/eventmesh.

EventMesh build around this cloudevents specification.
