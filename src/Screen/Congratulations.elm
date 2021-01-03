module Screen.Congratulations exposing (Congratulations, view)

import Html exposing (Html)
import Html.Attributes as Attr
import Screen.Game


type alias Congratulations =
    Screen.Game.FinalStats


view : Congratulations -> Html msg
view { totalMoves, totalFails, totalTime } =
    Html.div [ Attr.style "text-align" "center", Attr.style "color" "black" ]
        [ Html.p [ Attr.style "font-size" "5vw" ] [ Html.text "Congratulations!" ]
        , Html.p [ Attr.style "font-size" "3vw" ] [ Html.text <| "Total moves: " ++ String.fromInt totalMoves ]
        , Html.p [ Attr.style "font-size" "3vw" ] [ Html.text <| "Total time: " ++ String.fromInt totalTime ++ "s" ]
        , Html.p [ Attr.style "font-size" "3vw" ] [ Html.text <| "Failures: " ++ String.fromInt totalFails ]
        ]
