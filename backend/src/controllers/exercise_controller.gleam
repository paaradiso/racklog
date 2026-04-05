import wisp.{type Request, type Response}

pub fn index(_req: Request) -> Response {
  wisp.json_response("[]", 200)
}

pub fn store(_req: Request) -> Response {
  wisp.json_response("{}", 201)
}

pub fn show(_req: Request, _id: String) -> Response {
  wisp.json_response("{}", 200)
}

pub fn update(_req: Request, _id: String) -> Response {
  wisp.json_response("{}", 200)
}

pub fn destroy(_req: Request, _id: String) -> Response {
  wisp.response(204)
}
