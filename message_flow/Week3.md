```mermaid
sequenceDiagram
    Docker Container->>HTTPoison Process: SSE Stream
    HTTPoison Process->>Reader: AsyncChunk Message
    Reader->>Load Balancer: Parsed Json
    Load Balancer->>HashtagPrinter: Parsed Json
    Load Balancer->>Printer: Message ID , Parsed Json
    Printer->>OutputQueue: Message ID
    OutputQueue->>Printer: OK | ERROR
    WorkerManager->>WorkerPool: INCREASE | DECREASE
```