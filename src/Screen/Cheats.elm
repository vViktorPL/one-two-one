module Screen.Cheats exposing (Msg(..), view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import Screen.Game.Level.Index exposing (restLevels)


type Msg
    = SetLevel Int


levelCount : Int
levelCount =
    List.length restLevels + 1


view : Html Msg
view =
    Html.div [ Attr.style "background" "red" ]
        [ Html.h1 [ Attr.style "text-align" "center" ] [ Html.text "Select level:" ]
        , Html.ul [ Attr.style "cursor" "pointer", Attr.style "font-size" "32px" ] (List.map viewLevelOption (List.range 1 levelCount))
        ]


viewLevelOption : Int -> Html Msg
viewLevelOption levelNumber =
    Html.li
        [ Event.onClick <| SetLevel levelNumber ]
        [ Html.text <| String.fromInt levelNumber ]
