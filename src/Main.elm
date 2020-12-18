module Main exposing (Model, Msg(..), Screen(..), init, main, subscriptions, update, view)

import Browser
import Html exposing (Html)
import Screen.Congratulations exposing (Congratulations)
import Screen.Game exposing (Game)


type alias Model =
    { screen : Screen
    }


type Screen
    = GameScreen Game
    | CongratulationsScreen Congratulations


type Msg
    = GameMsg Screen.Game.Msg


init : () -> ( Model, Cmd Msg )
init flags =
    ( { screen = GameScreen Screen.Game.init }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg { screen } =
    case ( screen, msg ) of
        ( GameScreen game, GameMsg gameMsg ) ->
            case Screen.Game.update gameMsg game of
                ( updatedGame, Screen.Game.NoOp ) ->
                    ( { screen = GameScreen updatedGame }, Cmd.none )

                ( _, Screen.Game.GameFinished ) ->
                    ( { screen = CongratulationsScreen Screen.Congratulations.init }, Cmd.none )

        _ ->
            ( { screen = screen }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions { screen } =
    case screen of
        GameScreen game ->
            Sub.map GameMsg (Screen.Game.subscriptions game)

        CongratulationsScreen _ ->
            Sub.none


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


view : Model -> Html Msg
view { screen } =
    case screen of
        GameScreen game ->
            Html.map GameMsg (Screen.Game.view game)

        CongratulationsScreen congratulations ->
            Screen.Congratulations.view congratulations
