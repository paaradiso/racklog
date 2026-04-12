import glaze/oat/toast
import lustre/effect.{type Effect}

pub fn toast(
  title title: String,
  description description: String,
  variant variant: toast.Variant,
) -> Effect(msg) {
  effect.from(fn(_) {
    let options =
      toast.default_options(variant)
      |> toast.with_placement(toast.BottomRight)
      |> toast.with_duration(5000)
    // description and title are swapped?
    toast.dispatch(description, title, options)
  })
}
