import lustre/effect.{type Effect}
import lustre/element.{type Element}

pub type Model {
  Model
}

pub type Msg

pub fn init() -> #(Model, Effect(Msg)) {
  #(Model, effect.none())
}

pub fn update(model _model: Model, msg msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    _ -> #(Model, effect.none())
  }
}

pub fn view(_model: Model) -> List(Element(Msg)) {
  [element.text("settings page")]
}
