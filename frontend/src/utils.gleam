import formal/form.{type Form}
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

pub const root_error_field = "root"

pub fn add_form_custom_error(
  form form: Form(a),
  for key: String,
  msg msg: String,
) -> Form(a) {
  form.add_error(form, key, form.CustomError(msg))
}

pub fn add_form_root_error(form form: Form(a), msg message: String) -> Form(a) {
  add_form_custom_error(form, root_error_field, message)
}
