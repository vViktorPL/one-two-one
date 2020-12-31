module Screen.Menu exposing (Menu, Msg, MsgOut(..), init, update, view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event


type Menu
    = Menu { gameCanBeContinued : Bool, titleClicks : Int }


type Msg
    = TitleClick
    | ExternalMsg MsgOut


type MsgOut
    = StartGame
    | ContinueGame
    | ActivateCheats


rateGameUrl =
    "https://itch.io/jam/elm-game-jam-5/rate/860455"


clicksToActivateCheats : Int
clicksToActivateCheats =
    10


init : Bool -> Menu
init gameCanBeContinued =
    Menu { gameCanBeContinued = gameCanBeContinued, titleClicks = 0 }


update : Msg -> Menu -> ( Menu, Maybe MsgOut )
update msg (Menu menuData) =
    case msg of
        TitleClick ->
            let
                newTitleClickCount =
                    menuData.titleClicks + 1
            in
            ( Menu { menuData | titleClicks = newTitleClickCount }
            , if newTitleClickCount >= clicksToActivateCheats then
                Just ActivateCheats

              else
                Nothing
            )

        ExternalMsg msgOut ->
            ( Menu menuData, Just msgOut )


view : Menu -> Html Msg
view (Menu { gameCanBeContinued }) =
    Html.nav [ Attr.class "menu" ]
        [ Html.h1 [ Event.onClick TitleClick ] [ Html.text "One-two-one" ]
        , Html.ul []
            (List.drop
                (if gameCanBeContinued then
                    0

                 else
                    1
                )
                [ Html.li [ Event.onClick <| ExternalMsg ContinueGame ] [ Html.text "Continue" ]
                , Html.li [ Event.onClick <| ExternalMsg StartGame ] [ Html.text "New game" ]
                , Html.li [] [ Html.a [ Attr.href rateGameUrl, Attr.target "_blank" ] [ Html.text "Rate this game" ] ]
                ]
            )
        ]
