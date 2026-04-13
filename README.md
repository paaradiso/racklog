# racklog
WIP self-hosted workout tracker built in Gleam.

todo:
- [ ] better error handling and responses
- [ ] tables
    - [x] `weight_type` -> `equipment`
    - [x] add `preferred_unit` to `app_user`
    - [ ] add `muscle_group` to `exercise` maybe
    - [x] `workout` table for an entire workout session
    - [x] `workout_set` table
    - [x] `workout_exercise` table for a group of `workout_set`s in a `workout`
    - [ ] `routine` table for users to save routine `workout`s 
    - [ ] `routine_exercise` table for `workout_exercise`s in a `routine`
- [ ] admin route 
    - [ ] manage `equipment`
    - [ ] manage `exercise`
    - [x] show all user data on users tab
    - [x] finish user role selects on users tab
    - [x] check if forms in model are made empty when their dialogs close
- [ ] user settings
    - [ ] manage `equipment`
    - [ ] manage `exercise`
    - [ ] create `workout`s 
    - [ ] create `routine`s
- [ ] other workout types? climbing?
- [x] ~~add OutMsg type (in admin.gleam?) and show toasts in frontend.gleam~~ show toasts
- [ ] change login to use username (or both?)
