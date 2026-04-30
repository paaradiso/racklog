import gleam/dynamic/decode
import gleam/time/timestamp.{type Timestamp}

pub fn timestamp_decoder() -> decode.Decoder(Timestamp) {
  use timestamp_string <- decode.then(decode.string)

  case timestamp.parse_rfc3339(timestamp_string) {
    Ok(time) -> decode.success(time)
    Error(_) -> {
      timestamp.system_time()
      |> decode.failure("RFC 3339 formatted timestamp")
    }
  }
}
