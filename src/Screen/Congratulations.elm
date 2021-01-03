module Screen.Congratulations exposing (Congratulations, view)

import Html exposing (Html)
import Html.Attributes as Attr
import Screen.Game


type alias Congratulations =
    Screen.Game.Stats


view : Congratulations -> Html msg
view { moves, fails, time, continues } =
    Html.div [ Attr.style "text-align" "center", Attr.style "color" "black" ]
        [ Html.p [ Attr.style "font-size" "5vw" ] [ Html.text "Congratulations!" ]
        , Html.p [ Attr.style "font-size" "3vw" ] [ Html.text <| "Total moves: " ++ String.fromInt moves ]
        , Html.p [ Attr.style "font-size" "3vw" ] [ Html.text <| "Total time: " ++ String.fromInt time ++ "s" ]
        , Html.p [ Attr.style "font-size" "3vw" ] [ Html.text <| "Failures: " ++ String.fromInt fails ]
        , Html.p [ Attr.style "font-size" "3vw" ] [ Html.text <| "Continue count: " ++ String.fromInt continues ]
        ]
