module Main exposing (Model, Msg(..), Screen(..), init, main, subscriptions, update, view)

import Browser
import Browser.Dom
import Browser.Events
import Html exposing (Html)
import Screen.Congratulations exposing (Congratulations)
import Screen.Game exposing (Game)
import Task


type alias Model =
    { screen : Screen
    , screenDimensions : ( Int, Int )
    }


type Screen
    = GameScreen Game
    | CongratulationsScreen Congratulations


type Msg
    = GameMsg Screen.Game.Msg
    | ViewportSize ( Int, Int )


init : { mobile : Bool } -> ( Model, Cmd Msg )
init { mobile } =
    ( { screen = GameScreen (Screen.Game.init mobile), screenDimensions = ( 0, 0 ) }
    , Browser.Dom.getViewport
        |> Task.perform (\{ viewport } -> ViewportSize ( floor viewport.width, floor viewport.height ))
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model.screen, msg ) of
        ( _, ViewportSize dimensions ) ->
            ( { model | screenDimensions = dimensions }, Cmd.none )

        ( GameScreen game, GameMsg gameMsg ) ->
            case Screen.Game.update gameMsg game of
                ( updatedGame, Screen.Game.NoOp ) ->
                    ( { model | screen = GameScreen updatedGame }, Cmd.none )

                ( _, Screen.Game.GameFinished ) ->
                    ( { model | screen = CongratulationsScreen Screen.Congratulations.init }, Cmd.none )

        _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions { screen } =
    Sub.batch
        [ case screen of
            GameScreen game ->
                Sub.map GameMsg (Screen.Game.subscriptions game)

            CongratulationsScreen _ ->
                Sub.none
        , Browser.Events.onResize (\width height -> ViewportSize ( width, height ))
        ]


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


view : Model -> Html Msg
view { screen, screenDimensions } =
    case screen of
        GameScreen game ->
            Html.map GameMsg (Screen.Game.view screenDimensions game)

        CongratulationsScreen congratulations ->
            Screen.Congratulations.view congratulations
