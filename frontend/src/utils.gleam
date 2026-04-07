import gleam/option.{None}
import lustre/effect.{type Effect}
import modem
import rsvp

pub fn handle_unauthorised(error: rsvp.Error) -> Effect(a) {
  case error {
    rsvp.HttpError(response) | rsvp.UnhandledResponse(response)
      if response.status == 401
    -> modem.push("/login", None, None)
    _ -> effect.none()
  }
}
