module Screen.Menu exposing (Menu, MsgOut(..), init, view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event


type Menu
    = Menu Bool


type MsgOut
    = StartGame
    | ContinueGame


rateGameUrl =
    "https://itch.io/jam/elm-game-jam-5/rate/860455"


init : Bool -> Menu
init =
    Menu


view : Menu -> Html MsgOut
view (Menu canBeContinued) =
    Html.nav [ Attr.class "menu" ]
        [ Html.h1 [] [ Html.text "One-two-one" ]
        , Html.ul []
            (List.drop
                (if canBeContinued then
                    0

                 else
                    1
                )
                [ Html.li [ Event.onClick ContinueGame ] [ Html.text "Continue" ]
                , Html.li [ Event.onClick StartGame ] [ Html.text "New game" ]
                , Html.li [] [ Html.a [ Attr.href rateGameUrl, Attr.target "_blank" ] [ Html.text "Rate this game" ] ]
                ]
            )
        ]
