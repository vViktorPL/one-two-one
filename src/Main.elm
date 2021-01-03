port module Main exposing (Model, Msg(..), Screen(..), init, main, subscriptions, update, view)

import Browser
import Browser.Dom
import Browser.Events
import Html exposing (Html)
import Json.Decode
import Json.Encode
import Screen.Cheats
import Screen.Congratulations exposing (Congratulations)
import Screen.Game exposing (Game)
import Screen.Menu exposing (Menu)
import Task


type alias SaveGameState =
    { level : Int
    , stats : Screen.Game.Stats
    }


type alias Flags =
    { mobile : Bool
    , lastSave : SaveGameState
    }


type alias Model =
    { screen : Screen
    , screenDimensions : ( Int, Int )
    , mobile : Bool
    , lastSave : SaveGameState
    }


type Screen
    = MenuScreen Menu
    | GameScreen Game
    | CongratulationsScreen Congratulations
    | CheatsScreen


type Msg
    = GameMsg Screen.Game.Msg
    | ViewportSize ( Int, Int )
    | MenuMsg Screen.Menu.Msg
    | CheatsMsg Screen.Cheats.Msg


port saveGame : SaveGameState -> Cmd msg


initViewport : Cmd Msg
initViewport =
    Browser.Dom.getViewport
        |> Task.perform (\{ viewport } -> ViewportSize ( floor viewport.width, floor viewport.height ))


init : Flags -> ( Model, Cmd Msg )
init { mobile, lastSave } =
    ( { screen = MenuScreen (Screen.Menu.init (lastSave.level > 1))
      , screenDimensions = ( 0, 0 )
      , mobile = mobile
      , lastSave = lastSave
      }
    , initViewport
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model.screen, msg ) of
        ( GameScreen game, GameMsg gameMsg ) ->
            case Screen.Game.update gameMsg game of
                ( updatedGame, cmd, Screen.Game.NoOp ) ->
                    ( { model | screen = GameScreen updatedGame }
                    , Cmd.map GameMsg cmd
                    )

                ( updatedGame, cmd, Screen.Game.SaveGame level stats ) ->
                    ( { model | screen = GameScreen updatedGame, lastSave = { level = level, stats = stats } }
                    , Cmd.batch [ Cmd.map GameMsg cmd, saveGame { level = level, stats = stats } ]
                    )

                ( _, _, Screen.Game.GameFinished stats ) ->
                    ( { model | screen = CongratulationsScreen stats }
                    , saveGame { level = 1, stats = Screen.Game.initStats }
                    )

        ( MenuScreen menu, MenuMsg menuMsg ) ->
            let
                ( updatedMenu, menuAction ) =
                    Screen.Menu.update menuMsg menu
            in
            case menuAction of
                Just Screen.Menu.StartGame ->
                    let
                        ( game, gameCmd ) =
                            Screen.Game.init model.mobile 0 Screen.Game.initStats
                    in
                    ( { model
                        | screen = GameScreen game
                        , lastSave = { level = 0, stats = Screen.Game.initStats }
                      }
                    , Cmd.batch [ saveGame { level = 1, stats = Screen.Game.initStats }, Cmd.map GameMsg gameCmd ]
                    )

                Just Screen.Menu.ContinueGame ->
                    let
                        stats =
                            model.lastSave.stats

                        updatedStats =
                            { stats | continues = stats.continues + 1 }

                        ( game, gameCmd ) =
                            Screen.Game.init model.mobile (model.lastSave.level - 1) updatedStats
                    in
                    ( { model | screen = GameScreen game }
                    , Cmd.batch
                        [ Cmd.map GameMsg gameCmd
                        , saveGame { level = model.lastSave.level, stats = updatedStats }
                        ]
                    )

                Just Screen.Menu.ActivateCheats ->
                    ( { model
                        | screen = CheatsScreen
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( { model
                        | screen = MenuScreen updatedMenu
                      }
                    , Cmd.none
                    )

        ( CheatsScreen, CheatsMsg (Screen.Cheats.SetLevel levelNumber) ) ->
            let
                ( game, gameCmd ) =
                    Screen.Game.init model.mobile (levelNumber - 1) Screen.Game.initStats
            in
            ( { model | screen = GameScreen game }
            , Cmd.batch [ saveGame { level = levelNumber - 1, stats = Screen.Game.initStats }, Cmd.map GameMsg gameCmd ]
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
            Html.map MenuMsg (Screen.Menu.view menu)

        CheatsScreen ->
            Html.map CheatsMsg Screen.Cheats.view
