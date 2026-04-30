import gleam/http.{Get}
import gleam/json
import gleam/list
import gleeunit/should
import racklog/workout
import router
import util
import wisp/simulate

pub fn list_workouts_401_without_session_test() {
  use _, ctx <- util.with_db()

  let response =
    simulate.request(Get, "/api/workouts")
    |> router.handle_request(ctx)

  response.status
  |> should.equal(401)
}

pub fn list_workouts_200_empty_for_new_user_test() {
  use db, ctx <- util.with_db()
  let #(_user, session_id) = util.seed_user(db, "a")

  let response =
    simulate.browser_request(Get, "/api/workouts")
    |> util.simulate_session_cookie(session_id)
    |> router.handle_request(ctx)

  response.status
  |> should.equal(200)

  let assert Ok(workouts) =
    simulate.read_body(response)
    |> json.parse(workout.list_decoder())

  list.length(workouts)
  |> should.equal(0)
}
