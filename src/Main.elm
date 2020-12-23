port module Main exposing (Model, Msg(..), Screen(..), init, main, subscriptions, update, view)

import Browser
import Browser.Dom
import Browser.Events
import Html exposing (Html)
import Json.Decode
import Json.Encode
import Screen.Congratulations exposing (Congratulations)
import Screen.Game exposing (Game)
import Screen.Menu exposing (Menu)
import Task


type alias Flags =
    { mobile : Bool
    , lastLevel : Int
    }


type alias Model =
    { screen : Screen
    , screenDimensions : ( Int, Int )
    , mobile : Bool
    , lastLevel : Int
    }


type Screen
    = MenuScreen Menu
    | GameScreen Game
    | CongratulationsScreen Congratulations


type Msg
    = GameMsg Screen.Game.Msg
    | ViewportSize ( Int, Int )
    | MenuAction Screen.Menu.MsgOut


port saveGame : Int -> Cmd msg


initViewport : Cmd Msg
initViewport =
    Browser.Dom.getViewport
        |> Task.perform (\{ viewport } -> ViewportSize ( floor viewport.width, floor viewport.height ))


init : Flags -> ( Model, Cmd Msg )
init { mobile, lastLevel } =
    ( { screen = MenuScreen (Screen.Menu.init (lastLevel > 0))
      , screenDimensions = ( 0, 0 )
      , mobile = mobile
      , lastLevel = lastLevel
      }
    , initViewport
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model.screen, msg ) of
        ( GameScreen game, GameMsg gameMsg ) ->
            case Screen.Game.update gameMsg game of
                ( updatedGame, cmd, Screen.Game.NoOp ) ->
                    ( { model | screen = GameScreen updatedGame }, cmd )

                ( updatedGame, _, Screen.Game.SaveGame levelIndex ) ->
                    ( { model | screen = GameScreen updatedGame, lastLevel = levelIndex }, saveGame levelIndex )

                ( _, _, Screen.Game.GameFinished ) ->
                    ( { model | screen = CongratulationsScreen Screen.Congratulations.init, lastLevel = 0 }, saveGame 0 )

        ( MenuScreen _, MenuAction Screen.Menu.StartGame ) ->
            ( { model
                | screen = GameScreen (Screen.Game.init model.mobile 0)
                , lastLevel = 0
              }
            , saveGame 0
            )

        ( MenuScreen _, MenuAction Screen.Menu.ContinueGame ) ->
            ( { model
                | screen = GameScreen (Screen.Game.init model.mobile model.lastLevel)
              }
            , Cmd.none
            )

        ( _, ViewportSize dimensions ) ->
            ( { model | screenDimensions = dimensions }, Cmd.none )

        _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions { screen } =
    Sub.batch
        [ case screen of
            GameScreen game ->
                Sub.map GameMsg (Screen.Game.subscriptions game)

            _ ->
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

        MenuScreen menu ->
            Html.map MenuAction (Screen.Menu.view menu)
