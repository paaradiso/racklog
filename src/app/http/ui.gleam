import database/main/models/user/gen/user.{type User}
import gleam/io
import gleam/option.{type Option}
import gleam/string
import glimr/http/http.{type Response}
import glimr/response/response
import glimr/vite
import lustre/element.{type Element}
import resources/views/layout

pub fn render(
  user user: Option(User),
  children children: List(Element(Nil)),
) -> Response {
  layout.Model(user: user)
  |> layout.view(children)
  |> element.to_document_string()
  |> string.replace("VITE_TAGS", vite.tags("src/resources/ts/app.ts"))
  |> response.html(200)
}
