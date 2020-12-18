module Screen.Congratulations exposing (Congratulations, init, view)

import Html exposing (Html)


type alias Congratulations =
    ()


init : Congratulations
init =
    ()


view : Congratulations -> Html msg
view _ =
    Html.div [] [ Html.text "Congratulations!" ]
