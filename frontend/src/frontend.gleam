import components
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri.{type Uri}
import lucide_lustre
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import racklog/user.{type UserDto}
import route/admin
import route/equipment
import route/exercises
import route/login
import rsvp

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Path {
  IndexPath
  EquipmentPath
  ExercisesPath
  LoginPath
  AdminPath
}

type Route {
  Index
  Equipment(equipment.Model)
  Exercises(exercises.Model)
  Login(login.Model)
  Admin(admin.Model)
  NotFound(uri: Uri)
}

type Model {
  Model(route: Route, user: Option(UserDto))
}

type Msg {
  UserNavigatedTo(Uri)
  GotCurrentUser(Result(UserDto, rsvp.Error))
  EquipmentMsg(equipment.Msg)
  ExercisesMsg(exercises.Msg)
  LoginMsg(login.Msg)
  AdminMsg(admin.Msg)
}

fn uri_to_route(uri: Uri) -> #(Route, Effect(Msg)) {
  case uri.path_segments(uri.path) {
    [] | [""] -> #(Index, effect.none())
    ["equipment"] -> {
      let #(model, fx) = equipment.init()
      #(Equipment(model), effect.map(fx, EquipmentMsg))
    }
    ["exercises"] -> {
      let #(model, fx) = exercises.init()
      #(Exercises(model), effect.map(fx, ExercisesMsg))
    }
    ["login"] -> {
      let #(model, fx) = login.init()
      #(Login(model), effect.map(fx, LoginMsg))
    }
    ["admin"] | ["admin", ""] -> {
      #(Admin(admin.init().0), modem.replace("/admin/general", None, None))
    }

    ["admin", tab] -> {
      case admin.tab_name_to_tab(tab) {
        Some(tab) -> {
          let #(model, fx) = admin.init_with_tab(tab)
          #(Admin(model), effect.map(fx, AdminMsg))
        }
        None -> {
          #(Admin(admin.init().0), modem.replace("/admin/general", None, None))
        }
      }
    }
    _ -> #(NotFound(uri:), effect.none())
  }
}

fn href(path: Path) -> Attribute(msg) {
  let url = case path {
    IndexPath -> "/"
    EquipmentPath -> "/equipment"
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
  rsvp.get("/api/me", rsvp.expect_json(user.decoder(), GotCurrentUser))
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
    EquipmentMsg(route_msg), Equipment(route_model) -> {
      let #(m, fx) = equipment.update(route_model, route_msg)
      #(Model(..model, route: Equipment(m)), effect.map(fx, EquipmentMsg))
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
      attribute.class("flex overflow-hidden flex-col w-full h-screen"),
    ],
    [
      render_header(model),
      html.div(
        [
          attribute.class("flex overflow-hidden z-40 flex-1 w-full min-h-0"),
        ],
        case model.route {
          Index -> [html.text("index")]
          Equipment(m) -> view_route(m, equipment.view, EquipmentMsg)
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
        "flex relative z-50 justify-center items-center w-full h-16 border-b shadow-md shrink-0 bg-card border-border backdrop-blur-sm",
      ),
    ],
    [
      html.div(
        [attribute.class("container flex justify-between items-center")],
        [
          html.nav(
            [
              attribute.attribute("aria-label", "Primary"),
              attribute.class("flex gap-4 items-center"),
            ],
            [
              html.a(
                [
                  href(IndexPath),
                  attribute.class("mr-4 text-2xl font-bold text-foreground"),
                ],
                [
                  element.text("racklog"),
                ],
              ),

              components.link(attributes: [href(EquipmentPath)], children: [
                element.text("Equipment"),
              ]),
              components.link(attributes: [href(ExercisesPath)], children: [
                element.text("Exercises"),
              ]),
            ],
          ),

          html.nav(
            [
              attribute.attribute("aria-label", "Account"),
              attribute.class("flex gap-4 items-center"),
            ],
            [
              case model.user {
                option.Some(user) ->
                  element.fragment([
                    html.a(
                      [
                        href(AdminPath),

                        attribute.title("Admin"),
                      ],
                      [
                        lucide_lustre.settings([attribute.class("size-5")]),
                      ],
                    ),
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
