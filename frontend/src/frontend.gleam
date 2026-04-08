import components
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri.{type Uri}
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import route/admin
import route/exercises
import route/login
import route/weight_types
import rsvp

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type User {
  User(id: Int, username: String, email: String)
}

type Path {
  IndexPath
  WeightTypesPath
  ExercisesPath
  LoginPath
  AdminPath
}

type Route {
  Index
  WeightTypes(weight_types.Model)
  Exercises(exercises.Model)
  Login(login.Model)
  Admin(admin.Model)
  NotFound(uri: Uri)
}

type Model {
  Model(route: Route, user: Option(User))
}

type Msg {
  UserNavigatedTo(Uri)
  GotCurrentUser(Result(User, rsvp.Error))
  WeightTypesMsg(weight_types.Msg)
  ExercisesMsg(exercises.Msg)
  LoginMsg(login.Msg)
  AdminMsg(admin.Msg)
}

fn uri_to_route(uri: Uri) -> #(Route, Effect(Msg)) {
  case uri.path_segments(uri.path) {
    [] | [""] -> #(Index, effect.none())
    ["weight_types"] -> {
      let #(model, fx) = weight_types.init()
      #(WeightTypes(model), effect.map(fx, WeightTypesMsg))
    }
    ["exercises"] -> {
      let #(model, fx) = exercises.init()
      #(Exercises(model), effect.map(fx, ExercisesMsg))
    }
    ["login"] -> {
      let #(model, fx) = login.init()
      #(Login(model), effect.map(fx, LoginMsg))
    }
    ["admin"] -> {
      let #(model, fx) = admin.init()
      #(Admin(model), effect.map(fx, AdminMsg))
    }
    ["admin", tab] -> {
      let tab = admin.tab_name_to_tab(tab) |> option.unwrap(admin.GeneralTab)
      let #(model, fx) = admin.init_with_tab(tab)
      #(Admin(model), effect.map(fx, AdminMsg))
    }
    _ -> #(NotFound(uri:), effect.none())
  }
}

fn href(path: Path) -> Attribute(msg) {
  let url = case path {
    IndexPath -> "/"
    WeightTypesPath -> "/weight_types"
    ExercisesPath -> "/exercises"
    LoginPath -> "/login"
    AdminPath -> "/admin"
  }
  attribute.href(url)
}

fn init(_) -> #(Model, Effect(Msg)) {
  let uri = modem.initial_uri() |> result.unwrap(uri.empty)
  let nav_effect = modem.init(UserNavigatedTo)
  let #(route, route_effect) = uri_to_route(uri)
  let user_effect = fetch_current_user()
  #(
    Model(route:, user: None),
    effect.batch([nav_effect, route_effect, user_effect]),
  )
}

fn fetch_current_user() -> Effect(Msg) {
  rsvp.get("/api/me", rsvp.expect_json(decode_user(), GotCurrentUser))
}

fn decode_user() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.int)
  use username <- decode.field("username", decode.string)
  use email <- decode.field("email", decode.string)
  decode.success(User(id:, username:, email:))
}

fn update(model model: Model, msg msg: Msg) -> #(Model, Effect(Msg)) {
  case msg, model.route {
    GotCurrentUser(Ok(user)), _ -> #(
      Model(..model, user: Some(user)),
      effect.none(),
    )
    GotCurrentUser(Error(_)), _ -> #(Model(..model, user: None), effect.none())
    UserNavigatedTo(uri), _ -> {
      let #(route, fx) = uri_to_route(uri)
      #(Model(..model, route:), effect.batch([fx, fetch_current_user()]))
    }
    WeightTypesMsg(route_msg), WeightTypes(route_model) -> {
      let #(m, fx) = weight_types.update(route_model, route_msg)
      #(Model(..model, route: WeightTypes(m)), effect.map(fx, WeightTypesMsg))
    }
    ExercisesMsg(route_msg), Exercises(route_model) -> {
      let #(m, fx) = exercises.update(route_model, route_msg)
      #(Model(..model, route: Exercises(m)), effect.map(fx, ExercisesMsg))
    }
    LoginMsg(route_msg), Login(route_model) -> {
      let #(m, fx) = login.update(route_model, route_msg)
      #(Model(..model, route: Login(m)), effect.map(fx, LoginMsg))
    }
    AdminMsg(route_msg), Admin(route_model) -> {
      let #(m, fx) = admin.update(route_model, route_msg)
      #(Model(..model, route: Admin(m)), effect.map(fx, AdminMsg))
    }
    _, _ -> #(model, effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class("h-screen flex flex-col w-full overflow-hidden"),
    ],
    [
      render_header(model),
      html.div(
        [
          attribute.class("w-full flex-1 flex z-40 min-h-0 overflow-hidden"),
        ],
        case model.route {
          Index -> [html.text("index")]
          WeightTypes(m) -> view_route(m, weight_types.view, WeightTypesMsg)
          Exercises(m) -> view_route(m, exercises.view, ExercisesMsg)
          Login(m) -> view_route(m, login.view, LoginMsg)
          Admin(m) -> view_route(m, admin.view, AdminMsg)
          NotFound(_) -> [html.text("not found")]
        },
      ),
    ],
  )
}

fn view_route(
  model: model,
  route_view_fn: fn(model) -> List(Element(msg)),
  route_msg_fn: fn(msg) -> Msg,
) -> List(Element(Msg)) {
  route_view_fn(model)
  |> list.map(element.map(_, route_msg_fn))
}

fn render_header(model: Model) -> Element(Msg) {
  html.header(
    [
      attribute.class(
        "shrink-0 relative bg-card border-border z-50 flex h-16 w-full items-center justify-center border-b shadow-md backdrop-blur-sm",
      ),
    ],
    [
      html.div(
        [attribute.class("container flex items-center justify-between")],
        [
          html.nav(
            [
              attribute.attribute("aria-label", "Primary"),
              attribute.class("flex items-center gap-4"),
            ],
            [
              html.a(
                [
                  href(IndexPath),
                  attribute.class("text-foreground text-2xl font-bold mr-4"),
                ],
                [
                  element.text("racklog"),
                ],
              ),

              components.link(attributes: [href(WeightTypesPath)], children: [
                element.text("Weight Types"),
              ]),
              components.link(attributes: [href(ExercisesPath)], children: [
                element.text("Exercises"),
              ]),
            ],
          ),

          html.nav(
            [
              attribute.attribute("aria-label", "Account"),
              attribute.class("items-center gap-4 flex"),
            ],
            [
              case model.user {
                option.Some(user) ->
                  html.span([], [
                    element.text(user.username),
                  ])
                option.None ->
                  element.fragment([
                    components.link(attributes: [href(LoginPath)], children: [
                      element.text("Log In"),
                    ]),
                  ])
              },
            ],
          ),
        ],
      ),
    ],
  )
}
