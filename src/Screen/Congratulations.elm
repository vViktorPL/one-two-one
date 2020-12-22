module Screen.Congratulations exposing (Congratulations, init, view)

import Html exposing (Html)
import Html.Attributes as Attr


type alias Congratulations =
    ()


init : Congratulations
init =
    ()


view : Congratulations -> Html msg
view _ =
    Html.div [ Attr.style "font-size" "10vw", Attr.style "text-align" "center", Attr.style "color" "black" ] [ Html.text "Congratulations!" ]
