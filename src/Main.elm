module Main exposing (..)

import Html.App
import Html exposing (..)
import Html.Attributes exposing (..)


type alias Model =
    ()


initialModel : Model
initialModel =
    ()


type Msg
    = NothingYet


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


viewCanvas : Html Msg
viewCanvas =
    div
        [ style
            [ ( "width", "250px" )
            , ( "height", "250px" )
            , ( "border", "2px solid black" )
            ]
        ]
        [ div
            [ style
                [ ( "background-image", "url(https://cdn.pixabay.com/photo/2014/07/31/23/01/clock-407101_1280.jpg)" )
                , ( "background-size", "auto 250px" )
                , ( "height", "250px" )
                ]
            ]
            []
        ]


view : Model -> Html.Html Msg
view model =
    div
        [ style
            [ ( "padding", "8px" )
            ]
        ]
        [ viewCanvas
        , hr [] []
        , text <| toString model
        ]


main =
    Html.App.program
        { init = ( initialModel, Cmd.none )
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }
